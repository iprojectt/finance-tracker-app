import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();
  ApiService._();

  String _baseUrl = 'http://192.168.1.7:8000';

  Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_base_url') ?? 'http://192.168.1.7:8000';
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }

  String get baseUrl => _baseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-user-id': 'default_user',
      };

  Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$_baseUrl$path'), headers: _headers);
    _checkStatus(res);
    return jsonDecode(res.body);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _checkStatus(res);
    return jsonDecode(res.body);
  }

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _checkStatus(res);
    return jsonDecode(res.body);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _checkStatus(res);
    return jsonDecode(res.body);
  }

  Future<void> delete(String path) async {
    final res = await http.delete(Uri.parse('$_baseUrl$path'), headers: _headers);
    _checkStatus(res);
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body);
      throw Exception(body['detail'] ?? 'API Error ${res.statusCode}');
    }
  }

  // ── Dashboard ──────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboardSummary() async =>
      await get('/api/dashboard/summary');
      
  Future<List<dynamic>> getTrendData({String timeframe = 'day'}) async =>
      await get('/api/dashboard/summary/trend?timeframe=$timeframe');

  // ── Accounts ───────────────────────────────────────────
  Future<List<dynamic>> getAccounts() async => await get('/api/accounts/');
  Future<Map<String, dynamic>> createAccount(Map<String, dynamic> data) async =>
      await post('/api/accounts/', data);
  Future<Map<String, dynamic>> updateAccount(String id, Map<String, dynamic> data) async =>
      await put('/api/accounts/$id', data);
  Future<void> deleteAccount(String id) async => await delete('/api/accounts/$id');

  // ── Transactions ───────────────────────────────────────
  Future<List<dynamic>> getTransactions({String? accountId, String? category, String? month}) async {
    String path = '/api/transactions/?limit=200';
    if (accountId != null) path += '&account_id=$accountId';
    if (category != null) path += '&category=$category';
    if (month != null) path += '&month=$month';
    return await get(path);
  }

  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> data) async =>
      await post('/api/transactions/', data);
  Future<Map<String, dynamic>> updateTransaction(String id, Map<String, dynamic> data) async =>
      await put('/api/transactions/$id', data);
  Future<void> deleteTransaction(String id) async => await delete('/api/transactions/$id');

  // ── Loans ──────────────────────────────────────────────
  Future<List<dynamic>> getLoans() async => await get('/api/loans/');
  Future<Map<String, dynamic>> createLoan(Map<String, dynamic> data) async =>
      await post('/api/loans/', data);
  Future<Map<String, dynamic>> updateLoan(String id, Map<String, dynamic> data) async =>
      await put('/api/loans/$id', data);
  Future<Map<String, dynamic>> payEmi(String id) async =>
      await patch('/api/loans/$id/pay-emi');
  Future<Map<String, dynamic>> getLoanSchedule(String id) async =>
      await get('/api/loans/$id/schedule');
  Future<void> deleteLoan(String id) async => await delete('/api/loans/$id');

  // ── Investments ────────────────────────────────────────
  Future<List<dynamic>> getInvestments() async => await get('/api/investments/');
  Future<Map<String, dynamic>> createInvestment(Map<String, dynamic> data) async =>
      await post('/api/investments/', data);
  Future<Map<String, dynamic>> updateInvestment(String id, Map<String, dynamic> data) async =>
      await put('/api/investments/$id', data);
  Future<void> deleteInvestment(String id) async => await delete('/api/investments/$id');

  // ── Subscriptions ──────────────────────────────────────
  Future<List<dynamic>> getSubscriptions() async => await get('/api/subscriptions/');
  Future<Map<String, dynamic>> createSubscription(Map<String, dynamic> data) async =>
      await post('/api/subscriptions/', data);
  Future<Map<String, dynamic>> updateSubscription(String id, Map<String, dynamic> data) async =>
      await put('/api/subscriptions/$id', data);
  Future<Map<String, dynamic>> toggleSubscription(String id) async =>
      await patch('/api/subscriptions/$id/toggle');
  Future<void> deleteSubscription(String id) async => await delete('/api/subscriptions/$id');

  // ── Goals ──────────────────────────────────────────────
  Future<List<dynamic>> getGoals() async => await get('/api/goals/');
  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> data) async =>
      await post('/api/goals/', data);
  Future<Map<String, dynamic>> updateGoal(String id, Map<String, dynamic> data) async =>
      await put('/api/goals/$id', data);
  Future<Map<String, dynamic>> addGoalSavings(String id, double amount) async =>
      await patch('/api/goals/$id/add-savings?amount=$amount');
  Future<void> deleteGoal(String id) async => await delete('/api/goals/$id');

  // ── Categories ─────────────────────────────────────────
  Future<List<dynamic>> getCategories({String? month}) async {
    String path = '/api/categories/';
    if (month != null) path += '?month=$month';
    return await get(path);
  }
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async =>
      await post('/api/categories/', data);
  Future<void> deleteCategory(String id) async => await delete('/api/categories/$id');
}

