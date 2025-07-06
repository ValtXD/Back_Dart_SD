import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart' show env, load;

class DatabaseService {
  late final PostgreSQLConnection _connection;
  bool _isInitialized = false;

  /// Verifica se o banco já foi inicializado
  bool get isInitialized => _isInitialized;

  /// Inicializa a conexão com o banco e cria as tabelas se necessário
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Carrega as variáveis do .env
    load();

    _connection = PostgreSQLConnection(
      env['DB_HOST'] ?? 'localhost',
      int.parse(env['DB_PORT'] ?? '5432'),
      env['DB_NAME'] ?? 'funfono',
      username: env['DB_USER'] ?? 'postgres',
      password: env['DB_PASSWORD'] ?? '',
    );

    await _connection.open();
    await _setupDatabase();

    _isInitialized = true;
    print('💡 Database connection established');
  }

  /// Criação das tabelas necessárias no banco de dados
  Future<void> _setupDatabase() async {
    // Tabela de questionários
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS questionnaires (
        id UUID PRIMARY KEY,
        user_id UUID,
        age INTEGER,
        gender TEXT,
        respondent_type TEXT,
        speech_diagnosis TEXT[],
        difficult_sounds TEXT[],
        speech_therapy_history TEXT,
        favorite_foods TEXT[],
        hobbies TEXT[],
        preferred_movie_genres TEXT[],
        occupation TEXT,
        music_preferences TEXT[],
        daily_interactions TEXT[],
        preferred_communication TEXT,
        improvement_goals TEXT[],
        practice_frequency TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    // Tabela de tentativas de pronúncia
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS pronunciation_attempts (
        id SERIAL PRIMARY KEY,
        user_id UUID NOT NULL,
        palavra TEXT NOT NULL,
        som TEXT NOT NULL,
        fala_usuario TEXT NOT NULL,
        correto BOOLEAN NOT NULL,
        dica TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS speech_attempts (
        id SERIAL PRIMARY KEY,
        user_id UUID NOT NULL,
        frase TEXT NOT NULL,
        acertou BOOLEAN NOT NULL,
        erros TEXT,
        dicas TEXT,
        transcricao_usuario TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    // Tabela de lembretes (reminders)
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS reminders (
        id SERIAL PRIMARY KEY,
        user_id UUID NOT NULL,
        title TEXT NOT NULL,
        day_of_week INTEGER NOT NULL, 
        time TEXT NOT NULL,          
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    // Tabela para resultados do jogo "Palavra Rápida" -- NOVO
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS quick_word_game_results (
        id SERIAL PRIMARY KEY,
        user_id UUID NOT NULL,
        score INTEGER NOT NULL,
        correct_words TEXT[] NOT NULL,   
        incorrect_words TEXT[] NOT NULL, 
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    // NOVO: Tabela para resultados de "Palavras Diárias"
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS daily_word_attempts (
        id SERIAL PRIMARY KEY,
        user_id UUID NOT NULL,
        word TEXT NOT NULL,
        user_transcription TEXT, -- Pode ser nulo se não houver transcrição clara
        is_correct BOOLEAN NOT NULL,
        tip TEXT, -- Dica da IA
        created_at TIMESTAMPTZ DEFAULT NOW(),
        CONSTRAINT fk_daily_word_user_id
            FOREIGN KEY (user_id)
            REFERENCES users (id)
            ON DELETE CASCADE
      );
    ''');
  }

  /// Getter da conexão. Lança erro se ainda não foi inicializado.
  PostgreSQLConnection get connection {
    if (!_isInitialized) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _connection;
  }

  /// Fecha a conexão com o banco
  Future<void> close() async {
    if (_isInitialized) {
      await _connection.close();
      _isInitialized = false;
    }
  }
}
