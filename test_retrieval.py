import requests
import chromadb
from core.config import cfg

def test_search(query_text: str):
    print(f"\n🔍 Aranan Sorgu: '{query_text}'")

    # 1. Sorguyu Ollama ile vektöre çevir
    try:
        res = requests.post(
            f"{cfg.ollama_url}/api/embeddings",
            json={"model": cfg.embedding_model, "prompt": query_text},
            timeout=10
        )
        query_embedding = res.json()["embedding"]
    except Exception as e:
        print(f"❌ Ollama embedding alınamadı: {e}")
        return

    # 2. Doğrudan ChromaDB'den sorgulama yap
    try:
        client = chromadb.PersistentClient(path=cfg.db_path)
        collection = client.get_or_create_collection(name=cfg.collection_name)

        results = collection.query(
            query_embeddings=[query_embedding],
            n_results=3
        )

        docs = results.get("documents", [[]])[0]
        metas = results.get("metadatas", [[]])[0]

        if not docs:
            print("⚠️ Uygun sonuç bulunamadı.")
            return

        for i, (doc, meta) in enumerate(zip(docs, metas)):
            print(f"\n--- 🎯 Sonuç {i+1} ---")
            print(f"📁 Kaynak: {meta.get('source')} | Tip: {meta.get('type')} | Sayfa: {meta.get('page')}")
            print(f"📝 Metin: {doc[:300]}...")

    except Exception as e:
        print(f"❌ Veritabanı sorgu hatası: {e}")

if __name__ == "__main__":
    test_search("xbrli:identifier alanına ne yazılmalıdır?")
    test_search("e-Defter başvurusu nasıl yapılır?")