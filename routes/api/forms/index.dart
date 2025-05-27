import 'package:dart_frog/dart_frog.dart';
import '../../../models/form_model.dart';

Response onRequest(RequestContext context) {
  final form = _buildFormModel();
  return Response.json(body: form.toJson());
}

FormModel _buildFormModel() {
  return FormModel(
    id: 'initial_assessment',
    title: 'Formulário de Avaliação Inicial',
    sections: [
      FormSection(
        id: 'personal_info',
        title: '1. Informações Pessoais',
        questions: [
          FormQuestion(
            id: 'age',
            question: '1.1. Qual a sua idade?',
            type: 'number',
          ),
          FormQuestion(
            id: 'gender',
            question: '1.2. Gênero:',
            type: 'select',
            options: [
              'Masculino',
              'Feminino',
              'Prefiro não dizer',
              'Outros',
            ],
          ),
          FormQuestion(
            id: 'patient_role',
            question: '1.3. Você é o paciente ou está respondendo como responsável?',
            type: 'select',
            options: [
              'Sou o paciente',
              'Sou pai/mãe/responsável',
              'Sou cuidador ou acompanhante',
              'Outros',
            ],
          ),
        ],
      ),
      FormSection(
        id: 'clinical_info',
        title: '2. Informações Clínicas',
        questions: [
          FormQuestion(
            id: 'diagnosis',
            question: '2.1. Qual o diagnóstico relacionado à sua fala ou linguagem?',
            type: 'multi-select',
            isMultipleChoice: true,
            options: [
              'Atraso de fala',
              'Apraxia de fala',
              'Dislalia (dificuldade na articulação de certos sons)',
              'Disfemia (gagueira)',
              'Disartria (dificuldade motora na fala)',
              'Outros',
            ],
          ),
          FormQuestion(
            id: 'difficult_sounds',
            question: '2.2. Quais sons ou letras vocais você tem mais dificuldade em pronunciar?',
            type: 'multi-select',
            isMultipleChoice: true,
            options: [
              'Sons com "R" (ex: rato, carro)',
              'Sons com "S" ou "Z" (ex: sapo, casa)',
              'Sons nasais (ex: "m", "n", "nh")',
              'Vogais abertas/fechadas (ex: "é" x "ê")',
              'Combinações consonantais (ex: "bl", "tr", "pr")',
              'Outros',
            ],
          ),
          FormQuestion(
            id: 'previous_therapy',
            question: '2.3. Você já realizou acompanhamento com fonoaudiólogo anteriormente?',
            type: 'select',
            options: [
              'Sim, atualmente estou em acompanhamento',
              'Sim, mas não faço mais',
              'Não, será minha primeira vez',
              'Outros',
            ],
          ),
        ],
      ),
      FormSection(
        id: 'lifestyle',
        title: '3. Estilo de Vida e Preferências',
        questions: [
          FormQuestion(
            id: 'favorite_foods',
            question: '3.1. Quais são suas comidas favoritas?',
            type: 'multi-select',
            isMultipleChoice: true,
            options: [
              'Massas (ex: lasanha, macarrão, pizza)',
              'Doces (ex: chocolate, bolo, sorvete)',
              'Frutas (ex: banana, maçã, melancia)',
              'Salgados (ex: coxinha, pastel, pão de queijo)',
              'Lanches rápidos (ex: hambúrguer, cachorro-quente)',
              'Outros',
            ],
          ),
          FormQuestion(
            id: 'hobbies',
            question: '3.2. Quais são seus hobbies ou atividades de lazer?',
            type: 'multi-select',
            isMultipleChoice: true,
            options: [
              'Esportes (ex: futebol, natação, vôlei)',
              'Desenhar ou pintar',
              'Jogar videogame',
              'Ler livros ou gibis',
              'Ouvir música',
              'Outros',
            ],
          ),
          FormQuestion(
            id: 'movie_preferences',
            question: '3.3. Você costuma assistir a séries ou filmes? Quais gêneros prefere?',
            type: 'multi-select',
            isMultipleChoice: true,
            options: [
              'Ação ou aventura',
              'Comédia',
              'Animação',
              'Romance',
              'Ficção científica ou fantasia',
              'Outros',
            ],
          ),
          FormQuestion(
            id: 'occupation',
            question: '3.4. Qual sua profissão ou ocupação atual?',
            type: 'select',
            options: [
              'Estudante',
              'Profissional da área da saúde',
              'Trabalhador do comércio/serviços',
              'Profissional autônomo',
              'Aposentado/desempregado',
              'Outros',
            ],
          ),
          FormQuestion(
            id: 'music_preferences',
            question: '3.5. Que tipo de música você costuma ouvir?',
            type: 'multi-select',
            isMultipleChoice: true,
            options: [
              'Pop',
              'Sertanejo',
              'Funk',
              'Rock',
              'Música infantil',
              'Outros',
            ],
          ),
        ],
      ),
      FormSection(
        id: 'communication',
        title: '4. Hábitos de Comunicação',
        questions: [
          FormQuestion(
            id: 'daily_conversations',
            question: '4.1. Com quem você mais conversa no dia a dia?',
            type: 'multi-select',
            isMultipleChoice: true,
            options: [
              'Pais ou responsáveis',
              'Amigos',
              'Colegas de escola/trabalho',
              'Professores',
              'Cuidadores ou profissionais da saúde',
              'Outros',
            ],
          ),
          FormQuestion(
            id: 'communication_preference',
            question: '4.2. Você prefere se comunicar por:',
            type: 'select',
            options: [
              'Conversa falada (voz)',
              'Conversa por mensagens (texto)',
              'Áudios gravados',
              'Mistura de todos',
              'Outros',
            ],
          ),
        ],
      ),
      FormSection(
        id: 'expectations',
        title: '5. Expectativas com o App',
        questions: [
          FormQuestion(
            id: 'improvement_goals',
            question: '5.1. O que você espera melhorar com este aplicativo?',
            type: 'multi-select',
            isMultipleChoice: true,
            options: [
              'Falar com mais clareza',
              'Ter mais confiança ao conversar',
              'Aprender a pronunciar sons corretamente',
              'Treinar sozinho(a) de forma divertida',
              'Ajudar na continuidade da terapia',
              'Outros',
            ],
          ),
          FormQuestion(
            id: 'practice_frequency',
            question: '5.2. Com que frequência você gostaria de praticar com o app?',
            type: 'select',
            options: [
              'Todos os dias',
              'De 2 a 3 vezes por semana',
              'Apenas nos dias de terapia',
              'Quando estiver com tempo livre',
              'Outros',
            ],
          ),
        ],
      ),
    ],
  );
}