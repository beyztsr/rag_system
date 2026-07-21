import os
from ingest.parsers import parse_sch_file
from core.config import cfg

def print_sch_files():
    data_dir = cfg.data_dir
    
    if not os.path.exists(data_dir):
        print(f"⚠️ '{data_dir}' klasörü bulunamadı!")
        return

    # Klasördeki .sch ve .xml dosyalarını bul
    sch_files = [f for f in os.listdir(data_dir) if f.endswith('.sch') or f.endswith('.xml')]

    if not sch_files:
        print(f"⚠️ '{data_dir}' klasöründe hiç .sch veya .xml dosyası bulunamadı.")
        return

    print(f"🔍 Toplam {len(sch_files)} Schematron dosyası bulundu ve ayrıştırılıyor...\n")

    for file_name in sch_files:
        file_path = os.path.join(data_dir, file_name)
        print(f"==================================================")
        print(f"📂 DOSYA: {file_name}")
        print(f"==================================================")

        # Parser fonksiyonunu çalıştır
        chunks = parse_sch_file(file_path)

        if not chunks:
            print("⚠️ Bu dosyadan kural çıkarılamadı veya dosya boş.\n")
            continue

        for idx, chunk in enumerate(chunks, start=1):
            print(f"\n--- [PARÇA #{idx}] ---")
            print(f"📌 Metadata: {chunk.get('metadata')}")
            print(f"📜 İçerik:\n{chunk.get('text')}")
            print("-" * 40)
        
        print("\n")

if __name__ == "__main__":
    print_sch_files()