import 'package:flutter_bloc/flutter_bloc.dart';
import 'event.dart';
import 'state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<ToggleOrderAcceptance>(_onToggleOrderAcceptance);
  }

  void _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) {
    emit(HomeLoading());
    
    try {
      // Mock data that would normally come from an API
      emit(HomeLoaded(
        isAcceptingOrders: false,
        ordersCount: 248,
        productsCount: 86,
        tagsCount: 12,
        rating: 4.8,
        salesData: [
          {'day': 'Mon', 'sales': 800},
          {'day': 'Tue', 'sales': 920},
          {'day': 'Wed', 'sales': 900},
          {'day': 'Thu', 'sales': 950},
          {'day': 'Fri', 'sales': 1250},
          {'day': 'Sat', 'sales': 1300},
          {'day': 'Sun', 'sales': 1290},
        ],
      ));
    } catch (e) {
      emit(HomeError(message: 'Failed to load dashboard data'));
    }
  }

  void _onToggleOrderAcceptance(ToggleOrderAcceptance event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(isAcceptingOrders: event.isAccepting));
    }
  }
}