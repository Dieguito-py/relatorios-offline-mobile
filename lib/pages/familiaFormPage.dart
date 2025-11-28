import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import 'package:relatoriooffline/widgets/customDropdown.dart';
import 'package:relatoriooffline/widgets/custonItemQuantidade.dart';
import 'package:relatoriooffline/core/database/app_database.dart';
import 'package:relatoriooffline/services/syncService.dart';

class FamiliaFormPage extends StatefulWidget {
  const FamiliaFormPage({super.key});

  @override
  State<FamiliaFormPage> createState() => _FamiliaFormPageState();
}

class _FamiliaFormPageState extends State<FamiliaFormPage> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _controllers = {
    'nomeAtingido': TextEditingController(),
    'cpfAtingido': TextEditingController(),
    'rgAtingido': TextEditingController(),
    'dataNascimentoAtingido': TextEditingController(),
    'enderecoAtingido': TextEditingController(),
    'bairroAtingido': TextEditingController(),
    'cidadeAtingido': TextEditingController(),
    'complementoAtingido': TextEditingController(),

    'localizacao': TextEditingController(),
    'moradia': TextEditingController(),
    'danoResidencia': TextEditingController(),
    'estimativaDanoMoveis': TextEditingController(),
    'estimativaDanoEdificacao': TextEditingController(),
    'ocupacao': TextEditingController(),
    'tipoConstrucao': TextEditingController(),
    'alternativaMoradia': TextEditingController(),
    'observacaoImovel': TextEditingController(),

    'numeroTotalPessoas': TextEditingController(),
    'menores0a12': TextEditingController(),
    'menores13a17': TextEditingController(),
    'maiores18a59': TextEditingController(),
    'idosos60mais': TextEditingController(),
    'possuiNecessidadesEspeciais': TextEditingController(),
    'quantidadeNecessidadesEspeciais': TextEditingController(),
    'observacaoNecessidades': TextEditingController(),
    'usoMedicamentoContinuo': TextEditingController(),
    'medicamento': TextEditingController(),
    'possuiDesaparecidos': TextEditingController(),
    'quantidadeDesaparecidos': TextEditingController(),
    'quantidadeFeridos': TextEditingController(),
    'quantidadeObitos': TextEditingController(),

    'outrasNecessidades': TextEditingController(),
    'observacaoAssistencia': TextEditingController(),

    'qtdAguaPotavel5L': TextEditingController(),
    'qtdColchoesSolteiro': TextEditingController(),
    'qtdColchoesCasal': TextEditingController(),
    'qtdCestasBasicas': TextEditingController(),
    'qtdKitHigienePessoal': TextEditingController(),
    'qtdKitLimpeza': TextEditingController(),
    'qtdMoveis': TextEditingController(),
    'qtdRoupas': TextEditingController(),
    'qtdTelhas6mm': TextEditingController(),
    'qtdTelhas4mm': TextEditingController(),

    'qtdAguaPotavel5LQtd': TextEditingController(),
    'qtdColchoesSolteiroQtd': TextEditingController(),
    'qtdColchoesCasalQtd': TextEditingController(),
    'qtdCestasBasicasQtd': TextEditingController(),
    'qtdKitHigienePessoalQtd': TextEditingController(),
    'qtdKitLimpezaQtd': TextEditingController(),
    'qtdMoveisQtd': TextEditingController(),
    'qtdRoupasQtd': TextEditingController(),
    'qtdTelhas6mmQtd': TextEditingController(),
    'qtdTelhas4mmQtd': TextEditingController(),

    'coordenadoriaMunicipalId': TextEditingController(),
  };

  DateTime? _dataNascimentoSelecionada;
  double? _latitude;
  double? _longitude;

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  Future<void> _selecionarDataNascimento() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataNascimentoSelecionada ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Selecione a data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (picked != null) {
      setState(() {
        _dataNascimentoSelecionada = picked;
        _controllers['dataNascimentoAtingido']!.text = _formatarData(picked);
      });
    }
  }

  Future<void> _salvarFormulario() async {
    if (!(_formKey.currentState?.validate() ?? true)) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      final sucessoLocalizacao = await _capturarLocalizacao(showFeedback: false);
      if (!sucessoLocalizacao && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível obter a localização atual.')),
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Salvando formulário...')),
    );

    int? toInt(String? value) {
      if (value == null || value.isEmpty) return null;
      return int.tryParse(value);
    }

    double? toDouble(String? value) {
      if (value == null || value.isEmpty) return null;
      return double.tryParse(value.replaceAll(',', '.'));
    }

    bool? toBool(String? value) {
      if (value == null || value.isEmpty) return null;
      final normalized = value.toLowerCase();
      if (normalized == 'sim' || normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'nao' || normalized == 'não' || normalized == 'false' || normalized == '0') {
        return false;
      }
      return null;
    }

    final payload = {
      'nomeAtingido': _controllers['nomeAtingido']!.text,
      'cpfAtingido': _controllers['cpfAtingido']!.text,
      'rgAtingido': _controllers['rgAtingido']!.text,
      'dataNascimentoAtingido': _dataNascimentoSelecionada?.toIso8601String(),
      'enderecoAtingido': _controllers['enderecoAtingido']!.text,
      'bairroAtingido': _controllers['bairroAtingido']!.text,
      'cidadeAtingido': _controllers['cidadeAtingido']!.text,
      'complementoAtingido': _controllers['complementoAtingido']!.text,
      'localizacao': _controllers['localizacao']!.text,
      'moradia': _controllers['moradia']!.text,
      'danoResidencia': _controllers['danoResidencia']!.text,
      'estimativaDanoMoveis': toDouble(_controllers['estimativaDanoMoveis']!.text),
      'estimativaDanoEdificacao': toDouble(_controllers['estimativaDanoEdificacao']!.text),
      'ocupacao': _controllers['ocupacao']!.text,
      'tipoConstrucao': _controllers['tipoConstrucao']!.text,
      'alternativaMoradia': _controllers['alternativaMoradia']!.text,
      'observacaoImovel': _controllers['observacaoImovel']!.text,
      'numeroTotalPessoas': toInt(_controllers['numeroTotalPessoas']!.text),
      'menores0a12': toInt(_controllers['menores0a12']!.text),
      'menores13a17': toInt(_controllers['menores13a17']!.text),
      'maiores18a59': toInt(_controllers['maiores18a59']!.text),
      'idosos60mais': toInt(_controllers['idosos60mais']!.text),
      'possuiNecessidadesEspeciais': toBool(_controllers['possuiNecessidadesEspeciais']!.text) ?? false,
      'quantidadeNecessidadesEspeciais': toInt(_controllers['quantidadeNecessidadesEspeciais']!.text),
      'observacaoNecessidades': _controllers['observacaoNecessidades']!.text,
      'usoMedicamentoContinuo': toBool(_controllers['usoMedicamentoContinuo']!.text) ?? false,
      'medicamento': _controllers['medicamento']!.text,
      'possuiDesaparecidos': toBool(_controllers['possuiDesaparecidos']!.text) ?? false,
      'quantidadeDesaparecidos': toInt(_controllers['quantidadeDesaparecidos']!.text),
      'quantidadeFeridos': toInt(_controllers['quantidadeFeridos']!.text),
      'quantidadeObitos': toInt(_controllers['quantidadeObitos']!.text),
      'qtdAguaPotavel5L': toInt(_controllers['qtdAguaPotavel5LQtd']!.text) ?? 0,
      'qtdColchoesSolteiro': toInt(_controllers['qtdColchoesSolteiroQtd']!.text) ?? 0,
      'qtdColchoesCasal': toInt(_controllers['qtdColchoesCasalQtd']!.text) ?? 0,
      'qtdCestasBasicas': toInt(_controllers['qtdCestasBasicasQtd']!.text) ?? 0,
      'qtdKitHigienePessoal': toInt(_controllers['qtdKitHigienePessoalQtd']!.text) ?? 0,
      'qtdKitLimpeza': toInt(_controllers['qtdKitLimpezaQtd']!.text) ?? 0,
      'qtdMoveis': toInt(_controllers['qtdMoveisQtd']!.text) ?? 0,
      'qtdTelhas6mm': toInt(_controllers['qtdTelhas6mmQtd']!.text) ?? 0,
      'qtdTelhas4mm': toInt(_controllers['qtdTelhas4mmQtd']!.text) ?? 0,
      'qtdRoupas': toInt(_controllers['qtdRoupasQtd']!.text) ?? 0,
      'outrasNecessidades': _controllers['outrasNecessidades']!.text,
      'observacaoAssistencia': _controllers['observacaoAssistencia']!.text,
      'coordenadoriaMunicipalId': _controllers['coordenadoriaMunicipalId']!.text,
      'latitude': _latitude?.toString(),
      'longitude': _longitude?.toString(),
    };

    final dadosJson = jsonEncode(payload);

    AppDatabase.instance
        .salvarFormulario(tipo: 'familia', dadosJson: dadosJson)
        .then((id) async {
      final enviado = await SyncService.instance.trySendRelatorio(payload);

      if (enviado) {
        await AppDatabase.instance.marcarComoSincronizado(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Formulário sincronizado com sucesso.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sem conexão: formulário salvo como pendente.')),
          );
        }
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar formulário: $error')),
        );
      }
    });
  }

  Widget _tituloSecao(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 18,
          color: Colors.orange.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _campo(String key, {String? label, bool obrigatorio = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label ?? key,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: obrigatorio
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _campoDataNascimento() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers['dataNascimentoAtingido'],
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Data de Nascimento',
          suffixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onTap: _selecionarDataNascimento,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _capturarLocalizacao();
  }

  Future<bool> _capturarLocalizacao({bool showFeedback = true}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted && showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ative o serviço de localização para capturar latitude/longitude.')),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted && showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de localização negada.')),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted && showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de localização permanentemente negada. Configure nas definições.')),
        );
      }
      return false;
    }

    final posicao = await Geolocator.getCurrentPosition();
    setState(() {
      _latitude = posicao.latitude;
      _longitude = posicao.longitude;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro de Família"),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              _salvarFormulario();
            },
          )
        ],
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            _tituloSecao("Identificação do Atingido"),
            _campo('nomeAtingido', label: "Nome", obrigatorio: true),
            _campo('cpfAtingido', label: "CPF"),
            _campo('rgAtingido', label: "RG"),
            _campoDataNascimento(),
            _campo('enderecoAtingido', label: "Endereço"),
            _campo('bairroAtingido', label: "Bairro"),
            _campo('cidadeAtingido', label: "Cidade"),
            _campo('complementoAtingido', label: "Complemento"),

            _tituloSecao("Dados do Imóvel"),

            CustomDropdown(
              label: "Localização",
              controller: _controllers["localizacao"]!,
              opcoes: ["Rural", "Urbana"],
            ),

            CustomDropdown(
              label: "Moradia",
              controller: _controllers["moradia"]!,
              opcoes: ["Própria", "Alugada"],
            ),

            CustomDropdown(
              label: "Danos na Residência",
              controller: _controllers["danoResidencia"]!,
              opcoes: ["Danos Parcial", "Dano Total", "Sem Dano"],
            ),

            CustomDropdown(
              label: "Ocupação",
              controller: _controllers["ocupacao"]!,
              opcoes: ["Regular", "Irregular"],
            ),

            CustomDropdown(
              label: "Tipo de Construção",
              controller: _controllers["tipoConstrucao"]!,
              opcoes: ["Alvenaria", "Madeira", "Mista"],
            ),

            CustomDropdown(
              label: "Alternativa de Moradia",
              controller: _controllers["alternativaMoradia"]!,
              opcoes: [
                "Não Possui",
                "Possui Outra Casa",
                "Casa de Parentes/Amigos",
                "Abrigo Temporário",
                "Outros"
              ],
            ),


            _campo("observacaoImovel", label: "Observações"),


            _tituloSecao("Pessoas na Residência"),
            _campo('numeroTotalPessoas', label: "Número Total de Pessoas"),
            _campo('menores0a12', label: "Menores 0 a 12"),
            _campo('menores13a17', label: "Menores 13 a 17"),
            _campo('maiores18a59', label: "Maiores 18 a 59"),
            _campo('idosos60mais', label: "Idosos 60+"),

            CustomDropdown(
              label: "Necessidades Especiais",
              controller: _controllers["possuiNecessidadesEspeciais"]!,
              opcoes: ["Sim", "Não"],
            ),

            _campo("quantidadeNecessidadesEspeciais", label: "Quantidade"),
            _campo("observacaoNecessidades", label: "Observações"),

            CustomDropdown(
              label: "Uso de Medicamento Contínuo",
              controller: _controllers["usoMedicamentoContinuo"]!,
              opcoes: ["Sim", "Não"],
            ),

            CustomDropdown(
              label: "Possui Desaparecidos?",
              controller: _controllers["possuiDesaparecidos"]!,
              opcoes: ["Sim", "Não"],
            ),


            _campo("quantidadeDesaparecidos", label: "Quantidade Desaparecidos"),
            _campo("quantidadeFeridos", label: "Quantidade Feridos"),
            _campo("quantidadeObitos", label: "Quantidade Óbitos"),

            _tituloSecao("Assistência Humanitária - Necessidades Imediatas"),

            CustomItemQuantidade(
              label: "Água Potável 5L",
              controllerMarcado: _controllers["qtdAguaPotavel5L"]!,
              controllerQuantidade: _controllers["qtdAguaPotavel5LQtd"]!,
            ),

            CustomItemQuantidade(
              label: "Colchões Solteiro",
              controllerMarcado: _controllers["qtdColchoesSolteiro"]!,
              controllerQuantidade: _controllers["qtdColchoesSolteiroQtd"]!,
            ),

            CustomItemQuantidade(
              label: "Colchões Casal",
              controllerMarcado: _controllers["qtdColchoesCasal"]!,
              controllerQuantidade: _controllers["qtdColchoesCasalQtd"]!,
            ),

            CustomItemQuantidade(
              label: "Cesta Básica",
              controllerMarcado: _controllers["qtdCestasBasicas"]!,
              controllerQuantidade: _controllers["qtdCestasBasicasQtd"]!,
            ),

            CustomItemQuantidade(
              label: "Kit Higiene Pessoal",
              controllerMarcado: _controllers["qtdKitHigienePessoal"]!,
              controllerQuantidade: _controllers["qtdKitHigienePessoalQtd"]!,
            ),

            CustomItemQuantidade(
              label: "Kit Limpeza",
              controllerMarcado: _controllers["qtdKitLimpeza"]!,
              controllerQuantidade: _controllers["qtdKitLimpezaQtd"]!,
            ),

            CustomItemQuantidade(
              label: "Móveis",
              controllerMarcado: _controllers["qtdMoveis"]!,
              controllerQuantidade: _controllers["qtdMoveisQtd"]!,
            ),

            CustomItemQuantidade(
              label: "Roupas",
              controllerMarcado: _controllers["qtdRoupas"]!,
              controllerQuantidade: _controllers["qtdRoupasQtd"]!,
            ),

            _campo('outrasNecessidades', label: "Outros Itens"),
            _campo('observacaoAssistencia', label: "Observações"),

          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange.shade700,
        onPressed: () {
          _salvarFormulario();
        },
        icon: const Icon(Icons.save),
        label: const Text("Salvar"),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
