import fitz  # PyMuPDF
from PIL import Image
import io
import pytesseract
import xml.etree.ElementTree as ET
import os

def parse_sch_file(file_path: str) -> list:
    """
    SCH (Schematron ve XML Schema) dosyalarını okur, 
    içerisindeki Türkçe doğrulama kurallarını, alan tanımlarını ve hata mesajlarını ayıklar.
    """
    file_name = os.path.basename(file_path)
    extracted_text = f"e-Defter Şema ve Doğrulama Kuralları ({file_name}):\n\n"
    
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        
        extracted_rules = []
        
        # XML Namespace (ön ekler) ne olursa olsun tüm düğümleri gez
        for elem in root.iter():
            tag_name = elem.tag.split('}')[-1] if '}' in elem.tag else elem.tag
            
            # 1. Doküman Başlığı / Amacı (Schematron)
            if tag_name == 'title' and elem.text and elem.text.strip():
                extracted_text += f"📌 Kılavuz Amacı: {elem.text.strip()}\n\n"
            
            # 2. Schematron Assert Kuralları (Doğrulama ve mevzuat kuralları)
            elif tag_name == 'assert':
                rule_text = "".join(elem.itertext()).strip()
                test_condition = elem.get('test', '')
                if rule_text:
                    extracted_rules.append(f"• Kural / Hata Şartı: {rule_text} (Kod Kontrolü: {test_condition})")
            
            # 3. XSD Documentation (Genel Açıklamalar)
            elif tag_name == 'documentation' and elem.text and elem.text.strip():
                extracted_rules.append(f"• Açıklama: {elem.text.strip()}")

            # 4. XSD Element İsimleri (Teknik Alanlar)
            elif tag_name == 'element':
                name = elem.get('name')
                if name:
                    extracted_rules.append(f"• Eleman Tanımı: {name}")

        # Kuralları ana metne ekle
        if extracted_rules:
            extracted_text += "📋 Doğrulama ve Teknik Kurallar:\n" + "\n".join(extracted_rules)

        # Eğer özel etiket çıkarılamadıysa veya metin çok kısaysa düz metin olarak oku
        if len(extracted_text) < 100:
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                extracted_text = f.read()

        return [{
            "text": extracted_text,
            "metadata": {
                "source": file_name,
                "type": "sch_structure_text",
                "page": 1
            }
        }]
        
    except Exception as e:
        print(f"⚠️ [UYARI] SCH XML olarak okunamadı, ham metin deneniyor: {e}")
        try:
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            return [{
                "text": content,
                "metadata": {
                    "source": file_name,
                    "type": "sch_raw_text",
                    "page": 1
                }
            }]
        except Exception:
            return []

def process_pdf(file_path: str) -> list:
    """
    PDF dosyasındaki sayfaları gezer ve metadata ile birlikte metinleri ayıklar.
    """
    doc = fitz.open(file_path)
    parsed_pages = []
    file_name = os.path.basename(file_path)

    for page_num in range(len(doc)):
        page = doc[page_num]
        text = page.get_text()

        # Eğer metin yoksa OCR devreye girsin
        if not text.strip():
            pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
            image_data = pix.tobytes("png")
            image = Image.open(io.BytesIO(image_data))
            try:
                text = pytesseract.image_to_string(image, lang="tur")
            except Exception:
                text = "[Resim formatındaki sayfa okunamadı]"

        parsed_pages.append({
            "text": text,
            "metadata": {
                "source": file_name,
                "type": "pdf_standard_text",
                "page": page_num + 1
            }
        })

    doc.close()
    return parsed_pages