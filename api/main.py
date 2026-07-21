import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, HTMLResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from rag.engine import rag_engine

app = FastAPI(
    title="e-Defter Mevzuat Asistanı API",
    description="e-Defter kılavuzları ve şemaları için akıllı RAG sunucusu"
)

# CORS Ayarı: İleride yapacağın web arayüzünün bu API'ye sorunsuz bağlanabilmesini sağlar
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Görsel/Asset klasörünü dışarıya açıyoruz (Scrape edilen görsellerin arayüzde gösterilmesi için)
if os.path.exists("assets"):
    app.mount("/assets", StaticFiles(directory="assets"), name="assets")

# Kök dizine (http://localhost:8000) girildiğinde modern arayüzü sunuyoruz
@app.get("/", response_class=HTMLResponse)
async def read_root():
    html_path = os.path.join("ui", "index.html")
    if os.path.exists(html_path):
        with open(html_path, "r", encoding="utf-8") as f:
            return f.read()
    return "UI arayüz dosyası (ui/index.html) bulunamadı!"

# Arayüzden gelecek veri modelini tanımlıyoruz
class ChatRequest(BaseModel):
    session_id: str
    query: str

@app.post("/api/chat")
async def chat_endpoint(request: ChatRequest):
    """
    Arayüzden soruyu alır, RAG motorunu tetikler ve 
    gelen cevabı anlık olarak (stream) ekrana fırlatır.
    """
    generator = rag_engine.query(
        session_id=request.session_id, 
        query_text=request.query
    )
    return StreamingResponse(generator, media_type="text/event-stream")

if __name__ == "__main__":
    import uvicorn
    # Sunucuyu 8000 portunda ayağa kaldırıyoruz
    uvicorn.run("api.main:app", host="0.0.0.0", port=8000, reload=True)