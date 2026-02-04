class ProcessingTask {
  final String id;
  final String branchId;
  final String organizationId;
  final String recipeName;
  final String recipeId;
  final String menuItemId;
  final String status;
  final String assignedStaff;
  final DateTime assignedAt;
  final DateTime estimatedCompletionTime;
  final DateTime? actualCompletionTime;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int batchesRequested;
  final int batchesCompleted;
  final int priority;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Branch? branch;
  final Recipe? recipe;

  ProcessingTask({
    required this.id,
    required this.branchId,
    required this.organizationId,
    required this.recipeName,
    required this.recipeId,
    required this.menuItemId,
    required this.status,
    required this.assignedStaff,
    required this.assignedAt,
    required this.estimatedCompletionTime,
    this.actualCompletionTime,
    this.startedAt,
    this.completedAt,
    required this.batchesRequested,
    required this.batchesCompleted,
    required this.priority,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.branch,
    this.recipe,
  });

  factory ProcessingTask.fromJson(Map<String, dynamic> json) {
    return ProcessingTask(
      id: json['id'] ?? '',
      branchId: json['branchId'] ?? '',
      organizationId: json['organizationId'] ?? '',
      recipeName: json['recipeName'] ?? '',
      recipeId: json['recipeId'] ?? '',
      menuItemId: json['menuItemId'] ?? '',
      status: json['status'] ?? '',
      assignedStaff: json['assignedStaff'] ?? '',
      assignedAt: DateTime.parse(json['assignedAt']),
      estimatedCompletionTime: DateTime.parse(json['estimatedCompletionTime']),
      actualCompletionTime: json['actualCompletionTime'] != null
          ? DateTime.parse(json['actualCompletionTime'])
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      batchesRequested: json['batchesRequested'] ?? 0,
      batchesCompleted: json['batchesCompleted'] ?? 0,
      priority: json['priority'] ?? 0,
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      recipe: json['recipe'] != null ? Recipe.fromJson(json['recipe']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branchId': branchId,
      'organizationId': organizationId,
      'recipeName': recipeName,
      'recipeId': recipeId,
      'menuItemId': menuItemId,
      'status': status,
      'assignedStaff': assignedStaff,
      'assignedAt': assignedAt.toIso8601String(),
      'estimatedCompletionTime': estimatedCompletionTime.toIso8601String(),
      'actualCompletionTime': actualCompletionTime?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'batchesRequested': batchesRequested,
      'batchesCompleted': batchesCompleted,
      'priority': priority,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case 1:
        return 'High';
      case 2:
        return 'Medium';
      case 3:
        return 'Low';
      default:
        return 'Medium';
    }
  }
}

class Branch {
  final String id;
  final String name;
  final String branchCode;
  final String address;
  final String city;
  final String state;
  final String country;
  final String? zipCode;
  final String email;
  final bool isActive;

  Branch({
    required this.id,
    required this.name,
    required this.branchCode,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    this.zipCode,
    required this.email,
    required this.isActive,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      branchCode: json['branch_code'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      zipCode: json['zipCode'],
      email: json['email'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }
}

class Recipe {
  final String id;
  final String menuItemId;
  final int servingSize;
  final MenuItem? menuItem;

  Recipe({
    required this.id,
    required this.menuItemId,
    required this.servingSize,
    this.menuItem,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      menuItemId: json['menuItemId'] ?? '',
      servingSize: json['servingSize'] ?? 0,
      menuItem: json['menuItem'] != null
          ? MenuItem.fromJson(json['menuItem'])
          : null,
    );
  }
}

class MenuItem {
  final String id;
  final String dishName;
  final String description;
  final String category;
  final String price;
  final int preparationTime;
  final bool isAvailable;
  final String imageUrl;

  MenuItem({
    required this.id,
    required this.dishName,
    required this.description,
    required this.category,
    required this.price,
    required this.preparationTime,
    required this.isAvailable,
    required this.imageUrl,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      dishName: json['dishName'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? '',
      preparationTime: json['preparationTime'] ?? 0,
      isAvailable: json['isAvailable'] ?? false,
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}

// Request models
class CreateProcessingTaskRequest {
  final String branchId;
  final String recipeName;
  final String recipeId;
  final String menuItemId;
  final String assignedStaff;
  final int batchesRequested;
  final DateTime estimatedCompletionTime;
  final int priority;
  final String? notes;

  CreateProcessingTaskRequest({
    required this.branchId,
    required this.recipeName,
    required this.recipeId,
    required this.menuItemId,
    required this.assignedStaff,
    required this.batchesRequested,
    required this.estimatedCompletionTime,
    required this.priority,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'recipeName': recipeName,
      'recipeId': recipeId,
      'menuItemId': menuItemId,
      'assignedStaff': assignedStaff,
      'batchesRequested': batchesRequested,
      'estimatedCompletionTime': estimatedCompletionTime.toIso8601String(),
      'priority': priority,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

class UpdateProcessingTaskRequest {
  final String? status;
  final int? batchesCompleted;
  final DateTime? actualCompletionTime;
  final String? notes;

  UpdateProcessingTaskRequest({
    this.status,
    this.batchesCompleted,
    this.actualCompletionTime,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (status != null) data['status'] = status;
    if (batchesCompleted != null) data['batchesCompleted'] = batchesCompleted;
    if (actualCompletionTime != null) {
      data['actualCompletionTime'] = actualCompletionTime!.toIso8601String();
    }
    if (notes != null && notes!.isNotEmpty) data['notes'] = notes;
    return data;
  }
}

// Response wrapper
class ProcessingTaskResponse {
  final List<ProcessingTask> tasks;
  final String? message;

  ProcessingTaskResponse({required this.tasks, this.message});

  bool get isValid => tasks.isNotEmpty;

  factory ProcessingTaskResponse.fromJson(dynamic json) {
    if (json is List) {
      return ProcessingTaskResponse(
        tasks: json.map((item) => ProcessingTask.fromJson(item)).toList(),
      );
    } else if (json is Map<String, dynamic>) {
      return ProcessingTaskResponse(
        tasks: [ProcessingTask.fromJson(json)],
        message: json['message'],
      );
    }
    return ProcessingTaskResponse(tasks: []);
  }
}
