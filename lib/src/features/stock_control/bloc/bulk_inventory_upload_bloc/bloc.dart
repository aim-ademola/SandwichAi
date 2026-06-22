import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/bulk_inventory_upload_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/bulk_inventory_upload_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/bulk_inventory_upload_repo.dart';

class BulkInventoryUploadBloc
    extends Bloc<BulkInventoryUploadEvent, BulkInventoryUploadState> {
  final BulkInventoryUploadRepositoryInterface _repository;

  BulkInventoryUploadBloc({
    required BulkInventoryUploadRepositoryInterface repository,
  }) : _repository = repository,
       super(const BulkInventoryUploadInitial()) {
    on<UploadBulkInventoryFile>(_onUploadBulkInventoryFile);
    on<ResetBulkInventoryUpload>(_onResetBulkInventoryUpload);
  }

  Future<void> _onUploadBulkInventoryFile(
    UploadBulkInventoryFile event,
    Emitter<BulkInventoryUploadState> emit,
  ) async {
    emit(const BulkInventoryUploadInProgress(progress: 0));

    final response = await _repository.uploadInventoryFile(
      file: event.file,
      request: event.request,
      onSendProgress: (sent, total) {
        if (total > 0 && !emit.isDone) {
          emit(BulkInventoryUploadInProgress(progress: sent / total));
        }
      },
    );

    response.when(
      success: (data) => emit(BulkInventoryUploadSuccess(response: data)),
      error: (error) =>
          emit(BulkInventoryUploadFailure(message: error.message)),
    );
  }

  void _onResetBulkInventoryUpload(
    ResetBulkInventoryUpload event,
    Emitter<BulkInventoryUploadState> emit,
  ) {
    emit(const BulkInventoryUploadInitial());
  }
}
