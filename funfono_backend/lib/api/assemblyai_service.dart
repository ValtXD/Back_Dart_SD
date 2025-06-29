// funfono_backend/lib/api/assemblyai_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class AssemblyAIService {
  final String _apiKey;
  final String _uploadUrl = 'https://api.assemblyai.com/v2/upload';
  final String _transcriptUrl = 'https://api.assemblyai.com/v2/transcript';

  AssemblyAIService(this._apiKey);

  Map<String, String> get _headers => {
        'authorization': _apiKey,
        'Content-Type': 'application/json',
      };

  /// Converte o Base64 para bytes, faz o upload e retorna a URL do áudio no AssemblyAI.
  Future<String?> uploadAudio(String audioBase64) async {
    try {
      final audioBytes = base64Decode(audioBase64);

      final response = await http.post(
        Uri.parse(_uploadUrl),
        headers: {
          'authorization': _apiKey,
          'Content-Type': 'application/octet-stream',
        },
        body: audioBytes,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('AssemblyAI Upload Sucesso: ${data['upload_url']}'); // Log da URL de upload
        return data['upload_url'] as String?;
      } else {
        print('AssemblyAI Upload Erro: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('AssemblyAI Upload Exceção: $e');
      return null;
    }
  }

  /// Inicia o processo de transcrição e retorna o ID do job.
  Future<String?> createTranscriptionJob(String audioUrl) async {
    try {
      final response = await http.post(
        Uri.parse(_transcriptUrl),
        headers: _headers,
        body: jsonEncode({
          'audio_url': audioUrl,
          'language_code': 'pt',
        }),
      );

      // CORREÇÃO: Aceitar 200 OK ou 201 Created para o job, e verificar se 'id' está presente
      if ((response.statusCode == 200 || response.statusCode == 201)) {
        final data = jsonDecode(response.body);
        if (data.containsKey('id')) {
          print('AssemblyAI Create Job Sucesso. Job ID: ${data['id']}, Status: ${data['status']}'); // Log do job criado
          return data['id'] as String?;
        } else {
          print('AssemblyAI Create Job Erro: Status ${response.statusCode}, mas ID do job não encontrado na resposta: ${response.body}');
          return null;
        }
      } else {
        print('AssemblyAI Create Job Erro: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('AssemblyAI Create Job Exceção: $e');
      return null;
    }
  }

  /// Verifica o status de um job de transcrição.
  Future<Map<String, dynamic>?> getTranscriptionJobStatus(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse('$_transcriptUrl/$jobId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('AssemblyAI Get Status Erro: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('AssemblyAI Get Status Exceção: $e');
      return null;
    }
  }

  /// Transcreve um áudio completo: faz upload, cria job e espera pelo resultado.
  Future<String?> transcribeAudio(String audioBase64) async {
    final audioUrl = await uploadAudio(audioBase64);
    if (audioUrl == null) {
      print('AssemblyAI: Falha no upload do áudio.');
      return null;
    }

    final jobId = await createTranscriptionJob(audioUrl);
    if (jobId == null) {
      print('AssemblyAI: Falha ao criar job de transcrição (jobId é null).'); // Log mais específico
      return null;
    }

    String status = '';
    Map<String, dynamic>? jobDetails;
    // O polling deve ser mais robusto, verificando se jobDetails não é null.
    // O status "queued" é um status inicial válido.
    while (status != 'completed' && status != 'error' && status != 'failed') { // Adicionado 'failed'
      await Future.delayed(const Duration(seconds: 1));
      jobDetails = await getTranscriptionJobStatus(jobId);
      
      if (jobDetails == null) {
        print('AssemblyAI: Falha ao obter detalhes do job para ID $jobId.');
        return null; // Sai se não conseguir obter os detalhes do job
      }
      
      status = jobDetails['status']?.toString() ?? ''; 
      print('AssemblyAI: Job $jobId status: $status');

      // Se o job falhar por qualquer motivo antes de 'completed'
      if (status == 'error' || status == 'failed') {
        print('AssemblyAI: Job $jobId falhou. Erro: ${jobDetails['error']}');
        return null;
      }
    }

    if (status == 'completed') {
      return jobDetails?['text']?.toString();
    } else {
      // Este bloco só deve ser atingido se o loop for interrompido de forma inesperada
      print('AssemblyAI: Transcrição não concluída. Status final: $status - Erro: ${jobDetails?['error']}'); 
      return null;
    }
  }
}