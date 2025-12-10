import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
    'possuiFeridos': TextEditingController(),
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
  Uint8List? _fotoResidencia;
  final ImagePicker _picker = ImagePicker();
  bool _possuiNecessidadesEspeciais = false;
  bool _possuiDesaparecidos = false;
  bool _possuiFeridos = false;
  bool _isSubmitting = false;

  final _cpfFormatter = _CpfInputFormatter();
  late final NumberFormat _currencyFormat;
  late final _CurrencyInputFormatter _currencyInputFormatter;

  @override
  void initState() {
    super.initState();
    _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    _currencyInputFormatter = _CurrencyInputFormatter(_currencyFormat);
    _possuiNecessidadesEspeciais = _normalizeBool(_controllers['possuiNecessidadesEspeciais']!.text);
    _possuiDesaparecidos = _normalizeBool(_controllers['possuiDesaparecidos']!.text);
    _possuiFeridos = _normalizeBool(_controllers['possuiFeridos']!.text);
    _capturarLocalizacao();
  }

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

  void _setSubmitting(bool value) {
    if (mounted) {
      setState(() => _isSubmitting = value);
    } else {
      _isSubmitting = value;
    }
  }

  Future<void> _salvarFormulario() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? true)) {
      return;
    }

    _setSubmitting(true);

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

    double? _parseCurrency(String? value) {
      if (value == null || value.isEmpty) return null;
      final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleaned.isEmpty) return null;
      final cents = double.tryParse(cleaned);
      if (cents == null) return null;
      return cents / 100;
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
      'estimativaDanoMoveis': _parseCurrency(_controllers['estimativaDanoMoveis']!.text),
      'estimativaDanoEdificacao': _parseCurrency(_controllers['estimativaDanoEdificacao']!.text),
      'ocupacao': _controllers['ocupacao']!.text,
      'tipoConstrucao': _controllers['tipoConstrucao']!.text,
      'alternativaMoradia': _controllers['alternativaMoradia']!.text,
      'observacaoImovel': _controllers['observacaoImovel']!.text,
      'numeroTotalPessoas': toInt(_controllers['numeroTotalPessoas']!.text),
      'menores0a12': toInt(_controllers['menores0a12']!.text),
      'menores13a17': toInt(_controllers['menores13a17']!.text),
      'maiores18a59': toInt(_controllers['maiores18a59']!.text),
      'idosos60mais': toInt(_controllers['idosos60mais']!.text),
      'possuiNecessidadesEspeciais': _possuiNecessidadesEspeciais,
      'quantidadeNecessidadesEspeciais': _possuiNecessidadesEspeciais
          ? toInt(_controllers['quantidadeNecessidadesEspeciais']!.text)
          : 0,
      'observacaoNecessidades': _controllers['observacaoNecessidades']!.text,
      'usoMedicamentoContinuo': toBool(_controllers['usoMedicamentoContinuo']!.text) ?? false,
      'medicamento': _controllers['medicamento']!.text,
      'possuiDesaparecidos': _possuiDesaparecidos,
      'quantidadeDesaparecidos': _possuiDesaparecidos
          ? toInt(_controllers['quantidadeDesaparecidos']!.text)
          : 0,
      'quantidadeFeridos': _possuiFeridos
          ? toInt(_controllers['quantidadeFeridos']!.text)
          : 0,
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
      'fotoResidencia': _fotoResidencia != null ? base64Encode(_fotoResidencia!) : null,
    };

    final dadosJson = jsonEncode(payload);

    try {
      final id = await AppDatabase.instance.salvarFormulario(tipo: 'familia', dadosJson: dadosJson);
      final enviado = await SyncService.instance.trySendRelatorio(payload, localId: id);

      if (enviado) {
        await AppDatabase.instance.marcarComoSincronizado(id);
        if (mounted) {
          _mostrarSnack('Formulário sincronizado com sucesso.');
          _retornarAposSalvar();
        }
      } else {
        if (mounted) {
          _mostrarSnack('Sem conexão: formulário salvo como pendente.', sucesso: false);
          _retornarAposSalvar();
        }
      }
    } catch (error) {
      if (mounted) {
        _mostrarSnack('Erro ao salvar formulário: $error', sucesso: false);
      }
    } finally {
      _setSubmitting(false);
    }
  }

  void _mostrarSnack(String mensagem, {bool sucesso = true}) {
    if (!mounted) return;
    final cor = sucesso ? Colors.green.shade600 : Colors.red.shade700;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cor,
        content: Row(
          children: [
            Icon(
              sucesso ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(mensagem)),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _retornarAposSalvar() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context, true);
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

  Widget _campo(
    String key, {
    String? label,
    bool obrigatorio = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
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

  Future<void> _selecionarFotoResidencia() async {
    final XFile? imagem = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1600);
    if (imagem == null) return;
    final bytes = await imagem.readAsBytes();
    setState(() {
      _fotoResidencia = bytes;
    });
  }

  Widget _previewFotoResidencia() {
    if (_fotoResidencia == null) {
      return OutlinedButton.icon(
        onPressed: _selecionarFotoResidencia,
        icon: const Icon(Icons.photo_camera_back),
        label: const Text('Selecionar foto da residência'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _fotoResidencia!,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: _selecionarFotoResidencia,
              icon: const Icon(Icons.refresh),
              label: const Text('Trocar foto'),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () => setState(() => _fotoResidencia = null),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remover'),
            ),
          ],
        ),
      ],
    );
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

  bool _normalizeBool(String? value) {
    if (value == null) return false;
    final normalized = value.toLowerCase();
    return normalized == 'sim' || normalized == 'true' || normalized == '1';
  }

  void _updatePossui(String key, bool value, {TextEditingController? quantidadeController}) {
    setState(() {
      switch (key) {
        case 'necessidades':
          _possuiNecessidadesEspeciais = value;
          break;
        case 'desaparecidos':
          _possuiDesaparecidos = value;
          break;
        case 'feridos':
          _possuiFeridos = value;
          break;
      }
    });

    _controllers[
      key == 'necessidades'
          ? 'possuiNecessidadesEspeciais'
          : key == 'desaparecidos'
              ? 'possuiDesaparecidos'
              : 'possuiFeridos'
    ]?.text = value ? 'Sim' : 'Não';

    if (!value && quantidadeController != null) {
      quantidadeController.text = '';
    }
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
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isSubmitting ? null : _salvarFormulario,
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
            _campo('cpfAtingido',
                label: "CPF",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, _cpfFormatter]),
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

            _campoMonetario(
              'estimativaDanoMoveis',
              label: 'Estimativa de Dano em Móveis',
            ),
            _campoMonetario(
              'estimativaDanoEdificacao',
              label: 'Estimativa de Dano na Edificação',
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
            _campo('numeroTotalPessoas',
                label: "Número Total de Pessoas",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            _campo('menores0a12',
                label: "Menores 0 a 12",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            _campo('menores13a17',
                label: "Menores 13 a 17",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            _campo('maiores18a59',
                label: "Maiores 18 a 59",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            _campo('idosos60mais',
                label: "Idosos 60+",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),

            CustomDropdown(
              label: "Necessidades Especiais",
              controller: _controllers["possuiNecessidadesEspeciais"]!,
              opcoes: ["Sim", "Não"],
              onChanged: (value) {
                final possui = (value ?? '').toLowerCase() == 'sim';
                _updatePossui('necessidades', possui,
                    quantidadeController: _controllers['quantidadeNecessidadesEspeciais']);
              },
            ),

            if (_possuiNecessidadesEspeciais)
              _campo("quantidadeNecessidadesEspeciais",
                  label: "Quantidade",
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly]),

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
              onChanged: (value) {
                final possui = (value ?? '').toLowerCase() == 'sim';
                _updatePossui('desaparecidos', possui,
                    quantidadeController: _controllers['quantidadeDesaparecidos']);
              },
            ),

            if (_possuiDesaparecidos)
              _campo("quantidadeDesaparecidos",
                  label: "Quantidade Desaparecidos",
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly]),

            CustomDropdown(
              label: "Possui Feridos?",
              controller: _controllers["possuiFeridos"]!,
              opcoes: ["Sim", "Não"],
              onChanged: (value) {
                final possui = (value ?? '').toLowerCase() == 'sim';
                _updatePossui('feridos', possui,
                    quantidadeController: _controllers['quantidadeFeridos']);
              },
            ),

            if (_possuiFeridos)
              _campo("quantidadeFeridos",
                  label: "Quantidade Feridos",
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly]),

            _campo("quantidadeObitos",
                label: "Quantidade Óbitos",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),

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

            CustomItemQuantidade(
              label: "Telhas 6mm",
              controllerMarcado: _controllers["qtdTelhas6mm"]!,
              controllerQuantidade: _controllers["qtdTelhas6mmQtd"]!,
            ),

            CustomItemQuantidade(
              label: "Telhas 4mm",
              controllerMarcado: _controllers["qtdTelhas4mm"]!,
              controllerQuantidade: _controllers["qtdTelhas4mmQtd"]!,
            ),

            _campo('outrasNecessidades', label: "Outros Itens"),
            _campo('observacaoAssistencia', label: "Observações"),
            const SizedBox(height: 16),
            Text(
              'Foto da residência',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _previewFotoResidencia(),

          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _isSubmitting ? Colors.grey : Colors.orange.shade700,
        onPressed: _isSubmitting ? null : _salvarFormulario,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSubmitting ? 'Salvando...' : 'Salvar'),
      ),
    );
  }

  Widget _campoMonetario(String key, {required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: TextInputType.number,
        inputFormatters: [_currencyInputFormatter],
        decoration: InputDecoration(
          labelText: label,
          hintText: 'R\$ 0,00',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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

class _CpfInputFormatter extends TextInputFormatter {
  static const _maxLength = 11;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > _maxLength ? digits.substring(0, _maxLength) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if ((i == 2 || i == 5) && i != limited.length - 1) {
        buffer.write('.');
      } else if (i == 8 && i != limited.length - 1) {
        buffer.write('-');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  _CurrencyInputFormatter(this._formatter);

  final NumberFormat _formatter;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final value = double.parse(digits) / 100;
    final formatted = _formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

