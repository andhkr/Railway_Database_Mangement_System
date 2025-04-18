import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Supabase Database configuration
DB_NAME = os.getenv('SUPABASE_DB_NAME', 'postgres')  # Supabase typically uses 'postgres' as default DB name
DB_USER = os.getenv('SUPABASE_DB_USER')
DB_PASSWORD = os.getenv('SUPABASE_DB_PASSWORD')
DB_HOST = os.getenv('SUPABASE_DB_HOST')
DB_PORT = os.getenv('SUPABASE_DB_PORT', '5432')
# DB_SSL_MODE = os.getenv('SUPABASE_SSL_MODE', 'require')

# Connection pool configuration
DB_POOL_MIN_CONN = int(os.getenv('DB_POOL_MIN_CONN', '1'))
DB_POOL_MAX_CONN = int(os.getenv('DB_POOL_MAX_CONN', '10'))

# Database connection string (with SSL mode for Supabase)
DATABASE_URI = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Secret key for session management
SECRET_KEY = os.getenv('SECRET_KEY', "dev-secret-key")

# Optional: Supabase project URL and API key (if using Supabase Auth or other APIs)
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_KEY')