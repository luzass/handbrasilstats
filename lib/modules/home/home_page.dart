import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HandBrasil Stats'),
      ),
      body: Center(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: supabase.from('competitions').select(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text('Erro: ${snapshot.error}');
            }

            final data = snapshot.data ?? [];

            if (data.isEmpty) {
              return const Text('Nenhuma competição encontrada.');
            }

            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final competition = data[index];
                return ListTile(
                  title: Text(competition['name'] ?? 'Sem nome'),
                  subtitle: Text(
                    'Ano: ${competition['year'] ?? '-'} | Categoria: ${competition['category'] ?? '-'}',
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}