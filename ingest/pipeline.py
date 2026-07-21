import os
import uuid
import json
import hashlib
import requests
from typing import List, Dict, Any
from langchain_text_splitters import RecursiveCharacterTextSplitter

from core.config import cfg
from core.vector_store import ChromaVectorStore
from ingest.parsers import parse_sch_file, process_pdf

HASH_FILE = os.path.join(cfg.db_path, "ingested_hashes.json")

def get_file_hash(file_path: str) -> str:
    """Dosyanın SHA-256 hash değerini hesaplar."""
    hasher = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(8192):
            hasher.update(chunk)
    return hasher.hexdigest()

def load_processed_hashes() -> dict:
    """İşlenmiş dosya hash'lerini yükler."""
    if os.path.exists(HASH_FILE):
        try:
            with open(HASH_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def save_processed_hashes(hashes: dict):
    """İşlenmiş dosya hash'lerini kaydeder."""
    os.makedirs(os.path.dirname(HASH_FILE), exist_ok=True)
    with open(HASH_FILE, "w", encoding="utf-8") as f:
        json.dump(hashes, f, ensure_ascii=False, indent=2)

def detect_doc_type(file_name: str) -> str:
    """
    Dosya adına göre dokümanın kategorisini belirler.
    Bu etiket, RAG arama anında filtreleme (metadata filtering) yapabilmek için kullanılır.
    """
    lower = file_name.lower()
    if "saklama" in lower:
        return "saklama_kilavuzu"
    elif "uygulama" in lower or "rehber" in lower or "kilavuz" in lower:
        return "uygulama_kilavuzu"
    elif lower.endswith(".sch") or lower.endswith(".xml") or "schematron" in lower:
        return "schematron_xml"
    elif "teblig" in lower or "kanun" in lower or "mevzuat" in lower:
        return "mevzuat"
    return "genel_dokuman"

def sanitize_metadata(metadata: Dict[str, Any]) -> Dict[str, Any]:
    """
    ChromaDB sadece int, float, str ve bool tiplerini destekler.
    Karmaşık/iç içe tipleri string'e çevirerek veritabanı hatasını önler.
    """
    clean_meta = {}
    for key, value in metadata.items():
        if isinstance(value, (str, int, float, bool)):
            clean_meta[key] = value
        elif value is None:
            clean_meta[key] = ""
        else:
            clean_meta[key] = str(value)
    return clean_meta

def get_ollama_embedding(text: str) -> List[float]:
    """
    Ollama API üzerinden BGE-M3 modelini kullanarak metni vektöre dönüştürür.
    Yeni '/api/embed' ve eski '/api/embeddings' uç noktalarını destekler.
    """
    url = f"{cfg.ollama_url}/api/embed"
    payload = {"model": cfg.embedding_model, "input": text}
    
    try:
        res = requests.post(url, json=payload, timeout=60)
        if res.status_code == 404:  # Eski Ollama sürümleri için fallback
            url = f"{cfg.ollama_url}/api/embeddings"
            payload = {"model": cfg.embedding_model, "prompt": text}
            res = requests.post(url, json=payload, timeout=60)
            
        res.raise_for_status()
        res_json = res.json()

        if "embeddings" in res_json and res_json["embeddings"]:
            return res_json["embeddings"][0]
        elif "embedding" in res_json:
            return res_json["embedding"]
        else:
            raise ValueError(f"Ollama yanıtında vektör bulunamadı: {res_json}")

    except Exception as e:
        raise RuntimeError(f"Embedding alma hatası: {e}")

def run_pipeline():
    print("🚀 Veri yükleme fabrikası (Pipeline) çalışmaya başladı...")

    db = ChromaVectorStore(db_path=cfg.db_path, collection_name=cfg.collection_name)
    processed_hashes = load_processed_hashes()

    # BGE-M3 ve mevzuat metinleri için optimize edilmiş metin bölücü
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=cfg.chunk_size,
        chunk_overlap=cfg.chunk_overlap,
        separators=["\n\n", "\n", ". ", " ", ""]
    )

    data_dir = cfg.data_dir
    if not os.path.exists(data_dir):
        print(f"⚠️ '{data_dir}' klasörü bulunamadı!")
        return

    files = os.listdir(data_dir)
    if not files:
        print(f"⚠️ '{data_dir}' klasörünün içi boş!")
        return

    for file_name in files:
        file_path = os.path.join(data_dir, file_name)
        if os.path.isdir(file_path):
            continue

        current_hash = get_file_hash(file_path)

        # Hash Kontrolü: Dosya değişmediyse tekrar işleme
        if processed_hashes.get(file_name) == current_hash:
            print(f"⏩ [ATLANDI] {file_name} zaten kütüphanede mevcut ve güncel.")
            continue

        print(f"📄 Şu dosya işleniyor: {file_name}")

        raw_chunks = []
        doc_category = detect_doc_type(file_name)
        is_schematron = file_name.endswith(".sch") or file_name.endswith(".xml")

        # 1. Dosya Türüne Göre Okuma
        if file_name.endswith(".pdf"):
            raw_chunks = process_pdf(file_path)
        elif is_schematron:
            raw_chunks = parse_sch_file(file_path)
        elif file_name.endswith(".txt"):
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    txt_content = f.read()
                raw_chunks = [{
                    "text": txt_content,
                    "metadata": {"source": file_name, "page": 1}
                }]
            except Exception as txt_err:
                print(f"❌ [HATA] TXT okunamadı ({file_name}): {txt_err}")
                continue
        else:
            print(f"⏭️ Desteklenmeyen dosya formatı, atlandı: {file_name}")
            continue

        if not raw_chunks:
            print(f"⚠️ {file_name} içeriği okunamadı veya boş, atlanıyor...")
            continue

        final_documents = []
        final_metadatas = []
        final_ids = []
        final_embeddings = []

        # 2. Metinleri Parçalama ve BGE-M3 ile Vektörleştirme
        for chunk in raw_chunks:
            if not isinstance(chunk, dict):
                continue

            chunk_text = chunk.get("text", "")
            if not chunk_text.strip():
                continue

            # Mevcut metadata üzerine otomatik doküman türünü ekle
            chunk_metadata = chunk.get("metadata", {})
            if not isinstance(chunk_metadata, dict):
                chunk_metadata = {}

            chunk_metadata["source"] = file_name
            chunk_metadata["doc_type"] = doc_category  # Otomatik eklenen kategori etiketimiz

            sub_docs = text_splitter.split_text(chunk_text)

            for sub_doc in sub_docs:
                if not sub_doc.strip():
                    continue

                try:
                    embedding = get_ollama_embedding(sub_doc)
                except Exception as e:
                    print(f"❌ Embedding üretilemedi ({file_name}): {e}")
                    continue

                # ChromaDB uyumluluğu için metadataları temizle
                clean_meta = sanitize_metadata(chunk_metadata)

                final_documents.append(sub_doc)
                final_metadatas.append(clean_meta)
                final_ids.append(str(uuid.uuid4()))
                final_embeddings.append(embedding)

        # 3. Veritabanına Kaydetme ve Hash Güncelleme
        if final_documents:
            # Bellek/Payload şişmesini önlemek için 100'erli paketler halinde kaydetme
            batch_size = 100
            for i in range(0, len(final_documents), batch_size):
                db.add_documents(
                    ids=final_ids[i:i + batch_size],
                    embeddings=final_embeddings[i:i + batch_size],
                    documents=final_documents[i:i + batch_size],
                    metadatas=final_metadatas[i:i + batch_size]
                )

            processed_hashes[file_name] = current_hash
            save_processed_hashes(processed_hashes)
            print(f"✅ {file_name} kütüphaneye eklendi! (Kategori: {doc_category}, Parça Sayısı: {len(final_documents)})")
        else:
            print(f"⚠️ {file_name} için yüklenecek anlamlı parça üretilemedi.")

    print("\n🎉 İşlem tamamlandı. Kütüphane tamamen güncel!")

if __name__ == "__main__":
    run_pipeline()