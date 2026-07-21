import requests
import json
from typing import Optional, Dict, Any
from core.config import cfg
from core.vector_store import ChromaVectorStore

class RAGEngine:
    def __init__(self):
        # Veritabanı bağlantısını kuruyoruz
        self.db = ChromaVectorStore(db_path=cfg.db_path, collection_name=cfg.collection_name)
        # Oturum bazlı bellek (Session Memory): session_id -> [{"role": "user"/"assistant", "content": "..."}]
        self.sessions = {}
        
    def _get_query_embedding(self, query_text: str) -> Optional[list]:
        """
        Ollama API üzerinden arama metnini vektöre dönüştürür.
        Yükleme hattındaki (pipeline.py) esnek yapıyla birebir aynı mantıkta çalışır.
        """
        url = f"{cfg.ollama_url}/api/embed"
        payload = {"model": cfg.embedding_model, "input": query_text}
        
        try:
            res = requests.post(url, json=payload, timeout=15)
            if res.status_code == 404:  # Eski Ollama sürümleri için fallback
                url = f"{cfg.ollama_url}/api/embeddings"
                payload = {"model": cfg.embedding_model, "prompt": query_text}
                res = requests.post(url, json=payload, timeout=15)
                
            res.raise_for_status()
            res_json = res.json()

            if "embeddings" in res_json and res_json["embeddings"]:
                return res_json["embeddings"][0]
            elif "embedding" in res_json:
                return res_json["embedding"]
            else:
                return None
        except Exception as e:
            print(f"❌ [HATA] Embedding üretilirken sorun çıktı: {e}")
            return None

    def query(self, session_id: str, query_text: str, where_filter: Optional[Dict[str, Any]] = None):
        """
        SSE (Server-Sent Events) akışı sağlayan ana sorgu fonksiyonu.
        where_filter parametresi ile opsiyonel olarak metadata filtreleme yapabilir.
        """
        # 1. Adım: Sorunun vektörünü al
        query_vector = self._get_query_embedding(query_text)
        if query_vector is None:
            yield f"data: {json.dumps({'type': 'error', 'data': 'Embedding üretilemedi veya model yanıt vermedi.'}, ensure_ascii=False)}\n\n"
            return

        # 2. Adım: Veritabanından aday dokümanları getir (Iska oranını düşürmek için top_k=10 yapıldı)
        # ChromaVectorStore query() metodu query_vector adıyla parametre beklediği için açıkça belirtilmiştir.
        docs = self.db.query(query_vector=query_vector, top_k=10, where_filter=where_filter)
        
        sources = []
        context_entries = []
        for d in docs:
            sources.append(d["metadata"])
            context_entries.append(d["document"])
            
        # Kaynakları hemen arayüze/Swagger'a fırlatıyoruz
        yield f"data: {json.dumps({'type': 'sources', 'data': sources}, ensure_ascii=False)}\n\n"

        # 3. Adım: Yapay zekaya verilecek bağlamı ve katı sistem talimatlarını hazırla
        context = "\n---\n".join(context_entries)
        
        system_prompt = (
            "SEN KESİNLİKLE TÜRKÇE YAZAN BİR MEVZUAT VE TEKNİK DOKÜMAN ASİSTANISIN.\n\n"
            "KATI KURALLAR:\n"
            "1. BİLGİ YOKSA DÜRÜST OL: Eğer bağlam metninde sorunun DİREKT cevabı (örneğin spesifik ay isimleri, sayılar, tarihler) GEÇMİYORSA, KESİNLİKLE 'Sağlanan kılavuz parçalarında bu bilgi yer almamaktadır.' de.\n"
            "2. SORUYU TEKRARLAMA: Kullanıcının sorusunu cevabın içinde 'Bu bağlamda, ... hangi aylara ait beratların...' şeklinde KESİNLİKLE aynen tekrarlama. Doğrudan net cevaba gir.\n"
            "3. SADECE GERÇEKLER: Elindeki bağlamda olmayan hiçbir bilgiyi uydurma veya kendi genel bilgine göre yorumlama yapma.\n\n"
            f"BAĞLAM METİNLERİ:\n{context}"
        )

        # Oturum geçmişini başlat veya getir
        if session_id not in self.sessions:
            self.sessions[session_id] = []

        # Mesaj dizisini oluştur: Sistem promptu + Geçmiş mesajlar (Son 6 mesaj/3 tur) + Güncel soru
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(self.sessions[session_id][-6:])
        messages.append({"role": "user", "content": query_text})

        # 4. Adım: Ollama ile akış (Stream) iletişimini başlat
        url = f"{cfg.ollama_url}/api/chat"
        payload = {
            "model": cfg.text_model,
            "messages": messages,
            "stream": True,
            "options": {
                "temperature": 0.0,    # Deterministik yanıtlar (uydurmayı engeller)
                "top_p": 0.1,          # Yüksek olasılıklı doğru kelimeleri seçer
                "num_predict": 1024     # Yanıtın yarıda kesilmesini önler
            }
        }

        print(f"🤖 Ollama ({cfg.text_model}) modeline istek gönderiliyor...")
        
        full_response = ""
        try:
            response = requests.post(url, json=payload, stream=True, timeout=30)
            if response.status_code != 200:
                print(f"❌ [HATA] Ollama HTTP Hatası Döndü: {response.status_code}")
                yield f"data: {json.dumps({'type': 'error', 'data': f'Ollama HTTP {response.status_code} hatası verdi.'}, ensure_ascii=False)}\n\n"
                return
                
            for line in response.iter_lines():
                if line:
                    try:
                        chunk = json.loads(line.decode("utf-8"))
                        
                        # Ollama iç hatası kontrolü
                        if "error" in chunk:
                            print(f"❌ [HATA] Ollama İç Hatası: {chunk['error']}")
                            yield f"data: {json.dumps({'type': 'error', 'data': chunk['error']}, ensure_ascii=False)}\n\n"
                            break
                            
                        # Format esnekliği (/api/chat vs /api/generate)
                        content_chunk = ""
                        if "message" in chunk:
                            content_chunk = chunk["message"].get("content", "")
                        elif "response" in chunk:
                            content_chunk = chunk.get("response", "")
                            
                        if content_chunk:
                            full_response += content_chunk
                            yield f"data: {json.dumps({'type': 'content', 'data': content_chunk}, ensure_ascii=False)}\n\n"
                            
                    except Exception as json_err:
                        print(f"⚠️ [UYARI] Satır JSON'a dönüştürülemedi: {json_err}")
            
            # Akış başarıyla tamamlandığında hafızayı güncelle
            if full_response:
                self.sessions[session_id].append({"role": "user", "content": query_text})
                self.sessions[session_id].append({"role": "assistant", "content": full_response})
                        
        except Exception as e:
            print(f"❌ [HATA] Ollama ile konuşurken akış yarıda kesildi: {e}")
            yield f"data: {json.dumps({'type': 'error', 'data': f'Akış esnasında hata: {e}'}, ensure_ascii=False)}\n\n"

rag_engine = RAGEngine()