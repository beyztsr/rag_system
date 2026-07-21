import os
import hashlib
import asyncio
import base64
import requests
from bs4 import BeautifulSoup
from playwright.async_api import async_playwright
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.embeddings import OllamaEmbeddings
from langchain_chroma import Chroma

# Konfigürasyon Sabitleri
OLLAMA_BASE_URL = "http://localhost:11434"
EMBEDDING_MODEL = "nomic-embed-text"
VISION_MODEL = "llava" # veya llama3.2-vision
CHROMA_PATH = "./chroma_db"
TARGET_URL = "https://dokumanbulutu.com/public/s/sjEUjdB6GqLozKKffoZVTGLznXpfqdxy/genel-bakis"
IMAGES_DIR = "./assets/images"

os.makedirs(IMAGES_DIR, exist_ok=True)

def get_hash(text: str) -> str:
    return hashlib.sha256(text.encode('utf-8')).hexdigest()

def analyze_image_with_ollama(image_path: str, context_text: str) -> str:
    """Ollama Vision modeli ile görseli teknik doküman bağlamında açıklar."""
    with open(image_path, "rb") as img_file:
        encoded_image = base64.b64encode(img_file.read()).decode('utf-8')
    
    prompt = f"""Bu görsel bir e-Defter / teknik dokümantasyon sayfasından alınmıştır.
Bağlam/Çevreleyen Metin: {context_text}
Talimat: Bu görseli teknik dokümantasyon bağlamında detaylıca Türkçe açıkla. Ekran görüntüsüyse arayüz elemanlarını, buton/menü adlarını ve adımları net bir şekilde yaz."""

    try:
        response = requests.post(
            f"{OLLAMA_BASE_URL}/api/generate",
            json={
                "model": VISION_MODEL,
                "prompt": prompt,
                "images": [encoded_image],
                "stream": False
            },
            timeout=120
        )
        if response.status_code == 200:
            return response.json().get("response", "Görsel açıklanamadı.")
    except Exception as e:
        print(f"Görsel analiz hatası ({image_path}): {e}")
    return "Görsel analiz edilemedi."

async def scrape_dokuman_bulutu():
    print(f"🚀 Playwright ile {TARGET_URL} taranıyor...")
    
    docs_to_process = []
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        await page.goto(TARGET_URL, wait_until="networkidle")
        await page.wait_for_timeout(3000)

        links = await page.eval_on_selector_all("a", "elements => elements.map(e => e.href)")
        public_links = list(set([l for l in links if "sjEUjdB6GqLozKKffoZVTGLznXpfqdxy" in l]))
        if TARGET_URL not in public_links:
            public_links.append(TARGET_URL)

        print(f"📄 Toplam {len(public_links)} alt sayfa keşfedildi. Geziliyor...")

        for url in public_links:
            try:
                await page.goto(url, wait_until="networkidle")
                await page.wait_for_timeout(2000)
                
                title = await page.title()
                html_content = await page.content()
                
                soup = BeautifulSoup(html_content, 'html.parser')
                
                for redundant in soup(["nav", "footer", "aside", "header"]):
                    redundant.decompose()
                
                main_text = soup.get_text(separator="\n", strip=True)
                
                img_tags = soup.find_all('img')
                image_descriptions = []
                
                for img in img_tags:
                    img_url = img.get('src')
                    if img_url:
                        if img_url.startswith('/'):
                            from urllib.parse import urlparse
                            parsed_uri = urlparse(url)
                            img_url = f"{parsed_uri.scheme}://{parsed_uri.netloc}{img_url}"
                        
                        try:
                            img_data = requests.get(img_url, timeout=10).content
                            img_hash = get_hash(img_url)
                            img_filename = f"{img_hash}.png"
                            img_local_path = os.path.join(IMAGES_DIR, img_filename)
                            
                            with open(img_local_path, "wb") as f:
                                f.write(img_data)
                            
                            print(f"🤖 Görsel analiz ediliyor: {img_url}")
                            vision_desc = analyze_image_with_ollama(img_local_path, main_text[:300])
                            
                            image_descriptions.append({
                                "path": img_local_path,
                                "description": vision_desc,
                                "page_url": url
                            })
                        except Exception as img_err:
                            print(f"Görsel indirilemedi {img_url}: {img_err}")

                docs_to_process.append({
                    "url": url,
                    "title": title,
                    "text": main_text,
                    "images": image_descriptions
                })
                print(f"✔ Başarıyla işlendi: {title} ({url})")

            except Exception as page_err:
                print(f"Sayfa işlenirken hata oluştu {url}: {page_err}")

        await browser.close()

    print("📦 Metinler parçalanıyor (Chunking) ve ChromaDB'ye kaydediliyor...")
    
    embeddings = OllamaEmbeddings(base_url=OLLAMA_BASE_URL, model=EMBEDDING_MODEL)
    vectorstore = Chroma(persist_directory=CHROMA_PATH, embedding_function=embeddings)
    
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=700, chunk_overlap=100)
    
    for doc in docs_to_process:
        chunks = text_splitter.split_text(doc["text"])
        for chunk in chunks:
            if len(chunk.strip()) < 20: continue
            metadata = {
                "source": doc["url"],
                "title": doc["title"],
                "source_type": "web",
                "chunk_type": "text"
            }
            vectorstore.add_texts(texts=[chunk], metadatas=[metadata])

        for img_info in doc["images"]:
            img_chunk = f"[Görsel Açıklaması - Sayfa Başlığı: {doc['title']}]\n{img_info['description']}"
            metadata = {
                "source": img_info["page_url"],
                "title": doc["title"],
                "source_type": "web",
                "chunk_type": "image_description",
                "image_path": img_info["path"]
            }
            vectorstore.add_texts(texts=[img_chunk], metadatas=[metadata])

    print("🎉 Doküman Bulutu başarıyla tarandı ve RAG veritabanına işlendi!")

if __name__ == "__main__":
    asyncio.run(scrape_dokuman_bulutu())