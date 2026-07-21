import chromadb
from typing import List, Dict, Any, Optional

class ChromaVectorStore:
    """
    ChromaDB Vektör Depolama Sınıfı.
    Pipeline tarafından dışarıdan üretilen vektörlerle (Ollama / BGE-M3) 
    tam uyumlu çalışır; harici kütüphane çökme hatalarını engeller.
    """
    def __init__(
        self, 
        db_path: str, 
        collection_name: str, 
        model_name: str = "bge-m3", 
        provider: str = "none"  # 'none', 'ollama' veya 'sentence-transformers'
    ):
        self.client = chromadb.PersistentClient(path=db_path)
        self.embedding_fn = None

        # 1. Embedding Fonksiyonu Seçimi (Hata Toleranslı)
        if provider == "ollama":
            from chromadb.utils import embedding_functions
            ollama_model = "bge-m3" if model_name == "BAAI/bge-m3" else model_name
            self.embedding_fn = embedding_functions.OllamaEmbeddingFunction(
                url="http://localhost:11434/api/embeddings",
                model_name=ollama_model
            )
        elif provider == "sentence-transformers":
            try:
                from chromadb.utils import embedding_functions
                self.embedding_fn = embedding_functions.SentenceTransformerEmbeddingFunction(
                    model_name=model_name
                )
            except Exception as e:
                print(f"⚠️ 'sentence-transformers' yüklenemedi, harici vektör moduna geçiliyor: {e}")
                self.embedding_fn = None

        # 2. Koleksiyonun Oluşturulması
        self.collection = self.client.get_or_create_collection(
            name=collection_name,
            embedding_function=self.embedding_fn,
            metadata={"hnsw:space": "cosine"}
        )

    def add_documents(
        self, 
        ids: List[str], 
        documents: List[str], 
        metadatas: Optional[List[Dict[str, Any]]] = None,
        embeddings: Optional[List[List[float]]] = None
    ) -> None:
        """
        Dokümanları ekler veya günceller. 
        'pipeline.py' tarafından üretilen vektörler 'embeddings' ile doğrudan kaydedilir.
        """
        self.collection.upsert(
            ids=ids,
            documents=documents,
            metadatas=metadatas,
            embeddings=embeddings
        )

    def query(
        self, 
        query_text: Optional[str] = None,
        query_vector: Optional[List[float]] = None,
        top_k: int = 5,
        where_filter: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """
        Hem hazır vektör (query_vector) hem de ham metin (query_text) ile sorgulama yapmayı destekler.
        """
        # Pozisyonel argüman hatasını önleyen koruma: 
        # Eğer query_text parametresine string yerine bir list (vektör) geldiyse bunu query_vector'e aktarır.
        if isinstance(query_text, list) and query_vector is None:
            query_vector = query_text
            query_text = None

        if query_vector is not None:
            results = self.collection.query(
                query_embeddings=[query_vector],
                n_results=top_k,
                where=where_filter
            )
        elif query_text is not None:
            results = self.collection.query(
                query_texts=[query_text],
                n_results=top_k,
                where=where_filter
            )
        else:
            raise ValueError("Arama yapabilmek için 'query_text' veya 'query_vector' parametrelerinden biri verilmelidir.")
        
        formatted_results = []
        if results and results.get("documents") and len(results["documents"]) > 0:
            docs = results["documents"][0]
            metas = results["metadatas"][0] if results.get("metadatas") else [{}] * len(docs)
            ids = results["ids"][0] if results.get("ids") else [""] * len(docs)
            distances = results["distances"][0] if results.get("distances") else [0.0] * len(docs)

            for doc, meta, doc_id, dist in zip(docs, metas, ids, distances):
                formatted_results.append({
                    "id": doc_id,
                    "document": doc,
                    "metadata": meta or {},
                    "distance": dist
                })

        return formatted_results

    def count(self) -> int:
        """Koleksiyondaki toplam doküman sayısını döner."""
        return self.collection.count()