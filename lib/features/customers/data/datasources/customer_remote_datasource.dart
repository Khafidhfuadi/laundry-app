import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/customer_entity.dart';

abstract class CustomerRemoteDatasource {
  Future<List<CustomerEntity>> getCustomers();
  Future<CustomerEntity> getCustomerById(String id);
  Future<CustomerEntity> createCustomer(CustomerEntity customer);
  Future<CustomerEntity> updateCustomer(CustomerEntity customer);
  Future<List<CustomerEntity>> searchCustomers(String query);
}

class CustomerRemoteDatasourceImpl implements CustomerRemoteDatasource {
  final SupabaseClient supabaseClient;

  CustomerRemoteDatasourceImpl(this.supabaseClient);

  @override
  Future<List<CustomerEntity>> getCustomers() async {
    final response = await supabaseClient
        .from('customers')
        .select()
        .order('name');
    return (response as List).map((e) => CustomerEntity.fromJson(e)).toList();
  }

  @override
  Future<CustomerEntity> getCustomerById(String id) async {
    final response = await supabaseClient
        .from('customers')
        .select()
        .eq('id', id)
        .single();
    return CustomerEntity.fromJson(response);
  }

  @override
  Future<CustomerEntity> createCustomer(CustomerEntity customer) async {
    final response = await supabaseClient
        .from('customers')
        .insert(customer.toJson())
        .select()
        .single();
    return CustomerEntity.fromJson(response);
  }

  @override
  Future<CustomerEntity> updateCustomer(CustomerEntity customer) async {
    final response = await supabaseClient
        .from('customers')
        .update(customer.toJson())
        .eq('id', customer.id)
        .select()
        .single();
    return CustomerEntity.fromJson(response);
  }

  @override
  Future<List<CustomerEntity>> searchCustomers(String query) async {
    final response = await supabaseClient
        .from('customers')
        .select()
        .ilike('name', '%$query%')
        .order('name');
    return (response as List).map((e) => CustomerEntity.fromJson(e)).toList();
  }
}
