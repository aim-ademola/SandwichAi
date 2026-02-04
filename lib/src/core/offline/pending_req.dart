class PendingRequest {
  final String method; // POST | PUT
  final String url;
  final Map<String, dynamic> body;

  PendingRequest({required this.method, required this.url, required this.body});

  Map<String, dynamic> toJson() => {'method': method, 'url': url, 'body': body};

  factory PendingRequest.fromJson(Map<String, dynamic> json) {
    return PendingRequest(
      method: json['method'],
      url: json['url'],
      body: Map<String, dynamic>.from(json['body']),
    );
  }
}
