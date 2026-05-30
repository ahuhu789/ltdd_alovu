import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  GenerativeModel? _model;
  ChatSession? _chatSession;

  Future<void> initialize() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY không được tìm thấy trong file .env');
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        'Bạn là ALOVU Bot, một nhân viên tư vấn khách hàng thân thiện, chuyên nghiệp '
        'của ứng dụng đặt sân thể thao ALOVU. Nhiệm vụ của bạn là giải đáp thắc mắc về giá cả, '
        'luật lệ và hỗ trợ khách hàng đặt sân. Hãy trả lời ngắn gọn, lịch sự.'
        'Tuyệt đối không trả lời các câu hỏi không liên quan đến ALOVU.',
      ),
    );

    // Bắt đầu một session chat mới
    _chatSession = _model!.startChat(history: []);
  }

  Future<String> sendMessage(String text) async {
    if (_chatSession == null) {
      await initialize();
    }
    try {
      final response = await _chatSession!.sendMessage(Content.text(text));
      return response.text ?? 'Xin lỗi, tôi không thể trả lời lúc này.';
    } catch (e) {
      return 'Có lỗi xảy ra khi kết nối với máy chủ AI: $e';
    }
  }

  void resetChat() {
    if (_model != null) {
      _chatSession = _model!.startChat(history: []);
    }
  }
}
