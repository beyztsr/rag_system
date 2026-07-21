import os
import yaml

class Config:
    def __init__(self, config_path=None):
        # Eğer özel yol verilmediyse, bu dosyanın bulunduğu dizindeki config.yaml'ı bulur
        if config_path is None:
            base_dir = os.path.dirname(os.path.abspath(__file__))
            config_path = os.path.join(base_dir, "config.yaml")

        if not os.path.exists(config_path):
            raise FileNotFoundError(f"Konfigürasyon dosyası bulunamadı: {config_path}")

        with open(config_path, "r", encoding="utf-8") as f:
            self._cfg = yaml.safe_load(f) or {}

    # --- Ollama Ayarları ---
    @property
    def ollama_url(self) -> str:
        return self._cfg.get("ollama", {}).get("base_url", "http://localhost:11434")

    @property
    def text_model(self) -> str:
        return self._cfg.get("ollama", {}).get("text_model", "gemma4:31b-cloud")

    @property
    def vision_model(self) -> str:
        return self._cfg.get("ollama", {}).get("vision_model", "minicpm-v4.5:8b")

    @property
    def embedding_model(self) -> str:
        # Yeni bge-m3 modelimiz varsayılan yapıldı
        return self._cfg.get("ollama", {}).get("embedding_model", "bge-m3")

    # --- Vector Store Ayarları ---
    @property
    def db_path(self) -> str:
        return self._cfg.get("vector_store", {}).get("db_path", "./chroma_db")

    @property
    def provider(self) -> str:
        return self._cfg.get("vector_store", {}).get("provider", "chroma")

    @property
    def collection_name(self) -> str:
        return self._cfg.get("vector_store", {}).get("collection_name", "edefter_docs")

    # --- Ingest / Parçalama Ayarları ---
    @property
    def data_dir(self) -> str:
        return self._cfg.get("ingest", {}).get("data_dir", "./data")

    @property
    def image_dir(self) -> str:
        ingest_cfg = self._cfg.get("ingest", {})
        return ingest_cfg.get("image_output_dir") or ingest_cfg.get("image_dir", "./output_images")

    @property
    def chunk_size(self) -> int:
        # Teknik dokümanlarda anlamsal bütünlüğü korumak için ideal boyut
        return self._cfg.get("ingest", {}).get("chunk_size", 1000)

    @property
    def chunk_overlap(self) -> int:
        return self._cfg.get("ingest", {}).get("chunk_overlap", 150)


# Diğer modüllerin (pipeline.py vb.) doğrudan çağırabilmesi için oluşturulan nesne:
cfg = Config()