import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/customer_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/customer_repo.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepositoryInterface _repository;

  // Store current list for pagination
  List<CustomerModel> _allCustomers = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  String? _currentSearch;

  CustomerBloc({required CustomerRepositoryInterface repository})
    : _repository = repository,
      super(const CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<RefreshCustomers>(_onRefreshCustomers);
    on<LoadMoreCustomers>(_onLoadMoreCustomers);
    on<SearchCustomers>(_onSearchCustomers);
    on<LoadCustomerById>(_onLoadCustomerById);
    on<CreateCustomer>(_onCreateCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      emit(const CustomersLoading());

      _currentPage = event.page;
      _currentSearch = event.search;

      final response = await _repository.getCustomers(
        page: event.page,
        limit: event.limit,
        search: event.search,
      );

      await response.when(
        success: (customersResponse) async {
          _allCustomers = customersResponse.data;
          _currentPage = customersResponse.page;
          _totalPages = customersResponse.totalPages;
          _total = customersResponse.total;

          emit(
            CustomersLoaded(
              customers: _allCustomers,
              currentPage: _currentPage,
              totalPages: _totalPages,
              total: _total,
              hasMore: _currentPage < _totalPages,
            ),
          );
        },
        error: (error) async {
          emit(CustomersError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        CustomersError(error: 'An unexpected error occurred: ${e.toString()}'),
      );
    }
  }

  Future<void> _onRefreshCustomers(
    RefreshCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      // Show refreshing state with current data
      if (state is CustomersLoaded) {
        emit(
          CustomersRefreshing(
            currentCustomers: (state as CustomersLoaded).customers,
          ),
        );
      } else {
        emit(const CustomersLoading());
      }

      _currentPage = 1;
      _currentSearch = event.search;

      final response = await _repository.getCustomers(
        page: 1,
        limit: 10,
        search: event.search,
      );

      await response.when(
        success: (customersResponse) async {
          _allCustomers = customersResponse.data;
          _currentPage = customersResponse.page;
          _totalPages = customersResponse.totalPages;
          _total = customersResponse.total;

          emit(
            CustomersLoaded(
              customers: _allCustomers,
              currentPage: _currentPage,
              totalPages: _totalPages,
              total: _total,
              hasMore: _currentPage < _totalPages,
            ),
          );
        },
        error: (error) async {
          emit(CustomersError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        CustomersError(error: 'An unexpected error occurred: ${e.toString()}'),
      );
    }
  }

  Future<void> _onLoadMoreCustomers(
    LoadMoreCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      if (_currentPage >= _totalPages) return;

      emit(CustomersLoadingMore(currentCustomers: _allCustomers));

      final nextPage = _currentPage + 1;

      final response = await _repository.getCustomers(
        page: nextPage,
        limit: 10,
        search: _currentSearch,
      );

      await response.when(
        success: (customersResponse) async {
          _allCustomers.addAll(customersResponse.data);
          _currentPage = customersResponse.page;
          _totalPages = customersResponse.totalPages;
          _total = customersResponse.total;

          emit(
            CustomersLoaded(
              customers: _allCustomers,
              currentPage: _currentPage,
              totalPages: _totalPages,
              total: _total,
              hasMore: _currentPage < _totalPages,
            ),
          );
        },
        error: (error) async {
          emit(CustomersError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        CustomersError(error: 'An unexpected error occurred: ${e.toString()}'),
      );
    }
  }

  Future<void> _onSearchCustomers(
    SearchCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      emit(const CustomersLoading());

      _currentPage = 1;
      _currentSearch = event.query;

      final response = await _repository.getCustomers(
        page: 1,
        limit: 10,
        search: event.query,
      );

      await response.when(
        success: (customersResponse) async {
          _allCustomers = customersResponse.data;
          _currentPage = customersResponse.page;
          _totalPages = customersResponse.totalPages;
          _total = customersResponse.total;

          emit(
            CustomersLoaded(
              customers: _allCustomers,
              currentPage: _currentPage,
              totalPages: _totalPages,
              total: _total,
              hasMore: _currentPage < _totalPages,
            ),
          );
        },
        error: (error) async {
          emit(CustomersError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        CustomersError(error: 'An unexpected error occurred: ${e.toString()}'),
      );
    }
  }

  Future<void> _onLoadCustomerById(
    LoadCustomerById event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      emit(const CustomerDetailLoading());

      final response = await _repository.getCustomerById(event.id);

      await response.when(
        success: (customer) async {
          emit(CustomerDetailLoaded(customer: customer));
        },
        error: (error) async {
          emit(CustomerDetailError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        CustomerDetailError(
          error: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onCreateCustomer(
    CreateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      emit(const CustomerActionLoading());

      final response = await _repository.createCustomer(
        phone: event.phone,
        email: event.email,
        name: event.name,
        dateOfBirth: event.dateOfBirth,
        address: event.address,
        city: event.city,
        dietaryRestrictions: event.dietaryRestrictions,
        allowsMarketing: event.allowsMarketing,
        allowsSMS: event.allowsSMS,
        allowsEmail: event.allowsEmail,
      );

      await response.when(
        success: (customer) async {
          emit(CustomerCreated(customer: customer));
        },
        error: (error) async {
          emit(CustomerActionError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        CustomerActionError(
          error: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      emit(const CustomerActionLoading());

      final response = await _repository.updateCustomer(
        id: event.id,
        phone: event.phone,
        email: event.email,
        name: event.name,
        dateOfBirth: event.dateOfBirth,
        address: event.address,
        city: event.city,
        dietaryRestrictions: event.dietaryRestrictions,
        allowsMarketing: event.allowsMarketing,
        allowsSMS: event.allowsSMS,
        allowsEmail: event.allowsEmail,
      );

      await response.when(
        success: (customer) async {
          emit(CustomerUpdated(customer: customer));
        },
        error: (error) async {
          emit(CustomerActionError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        CustomerActionError(
          error: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      emit(const CustomerActionLoading());

      final response = await _repository.deleteCustomer(event.id);

      await response.when(
        success: (result) async {
          emit(const CustomerDeleted());
        },
        error: (error) async {
          emit(CustomerActionError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        CustomerActionError(
          error: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }
}
