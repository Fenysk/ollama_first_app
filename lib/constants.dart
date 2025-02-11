const String defaultSelectedModel = 'llama3.2-vision';

final List<Map<String, dynamic>> availableModels = [
  {'name': 'mistral-small', 'supportsImages': false},
  {'name': 'llama3.2-vision', 'supportsImages': true},
];

const String ollamaBaseUrl = 'http://localhost:11434/api';
