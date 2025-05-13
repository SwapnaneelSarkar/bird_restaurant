// lib/presentation/screens/add_product/bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'event.dart';
import 'state.dart';

class AddProductBloc extends Bloc<AddProductEvent, AddProductState> {
  AddProductBloc() : super(AddProductInitial()) {
    on<AddProductInitEvent>(_onInitialize);
    on<ProductNameChangedEvent>(_onNameChanged);
    on<ProductDescriptionChangedEvent>(_onDescriptionChanged);
    on<ProductCategoryChangedEvent>(_onCategoryChanged);
    on<ProductPriceChangedEvent>(_onPriceChanged);
    on<ProductTagsChangedEvent>(_onTagsChanged);
    on<ProductImageSelectedEvent>(_onImageSelected);
    on<ToggleCodAllowedEvent>(_onToggleCodAllowed);
    on<ToggleTaxIncludedEvent>(_onToggleTaxIncluded);
    on<ToggleCancellableEvent>(_onToggleCancellable);
    on<SubmitProductEvent>(_onSubmitProduct);
    on<ResetFormEvent>(_onResetForm);
  }

  void _onInitialize(AddProductInitEvent event, Emitter<AddProductState> emit) {
    // In a real app, we might fetch categories from an API
    final categories = [
      'Food',
      'Beverages',
      'Desserts',
      'Snacks',
      'Appetizers',
      'Main Course'
    ];
    
    emit(AddProductFormState(
      product: ProductModel(),
      categories: categories,
    ));
  }

  void _onNameChanged(ProductNameChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(name: event.name),
      ));
    }
  }

  void _onDescriptionChanged(ProductDescriptionChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(description: event.description),
      ));
    }
  }

  void _onCategoryChanged(ProductCategoryChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(category: event.category),
      ));
    }
  }

  void _onPriceChanged(ProductPriceChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(price: event.price),
      ));
    }
  }

  void _onTagsChanged(ProductTagsChangedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(tags: event.tags),
      ));
    }
  }

  void _onImageSelected(ProductImageSelectedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(image: event.image),
      ));
    }
  }

  void _onToggleCodAllowed(ToggleCodAllowedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(codAllowed: event.isAllowed),
      ));
    }
  }

  void _onToggleTaxIncluded(ToggleTaxIncludedEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(taxIncluded: event.isIncluded),
      ));
    }
  }

  void _onToggleCancellable(ToggleCancellableEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: currentState.product.copyWith(isCancellable: event.isCancellable),
      ));
    }
  }

  void _onSubmitProduct(SubmitProductEvent event, Emitter<AddProductState> emit) async {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      
      // Validation
      if (currentState.product.name.isEmpty) {
        emit(currentState.copyWith(errorMessage: 'Product name is required'));
        return;
      }
      
      if (currentState.product.category.isEmpty) {
        emit(currentState.copyWith(errorMessage: 'Please select a category'));
        return;
      }
      
      if (currentState.product.price <= 0) {
        emit(currentState.copyWith(errorMessage: 'Please enter a valid price'));
        return;
      }
      
      // Start submission
      emit(currentState.copyWith(isSubmitting: true, errorMessage: null));
      
      try {
        // In a real app, this would be an API call
        await Future.delayed(const Duration(seconds: 1));
        
        // Success
        emit(currentState.copyWith(isSubmitting: false, isSuccess: true));
      } catch (e) {
        // Error
        emit(currentState.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to add product: ${e.toString()}',
        ));
      }
    }
  }

  void _onResetForm(ResetFormEvent event, Emitter<AddProductState> emit) {
    if (state is AddProductFormState) {
      final currentState = state as AddProductFormState;
      emit(currentState.copyWith(
        product: ProductModel(),
        errorMessage: null,
        isSuccess: false,
      ));
    }
  }
}