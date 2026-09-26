import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

enum LegalDocumentKind { privacy, terms }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.kind});

  final LegalDocumentKind kind;

  String get _title => switch (kind) {
        LegalDocumentKind.privacy => 'Política de privacidade',
        LegalDocumentKind.terms => 'Termos de uso',
      };

  String get _body => switch (kind) {
        LegalDocumentKind.privacy => _privacyPt,
        LegalDocumentKind.terms => _termsPt,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          _body,
          style: const TextStyle(color: Colors.white70, height: 1.55, fontSize: 14),
        ),
      ),
    );
  }
}

const _privacyPt = '''
POLÍTICA DE PRIVACIDADE — ROTA PRIME
Última atualização: setembro de 2026

1. Quem somos
O ROTA PRIME é um aplicativo de apoio a entregadores para organizar paradas, importar planilhas de romaneio e conduzir rotas no mapa. O desenvolvimento é identificado como DEV ALN (desenvolvedor deste APK).

2. Dados que o app utiliza
• Planilhas e paradas que você importa ou digita (endereços, códigos de pacote, ordem de entrega).
• Localização GPS, quando você autoriza, para posicionar o mapa, origem da rota e navegação externa (Waze/Google Maps).
• Preferências salvas no aparelho (configurações de mapa, colunas visíveis, plano Gratuito ou PRO).
• O app não vende seus dados a terceiros.

3. Onde os dados ficam
• Rotas, paradas e configurações são armazenadas principalmente no seu celular (banco local).
• Planilhas importadas podem ficar em cache temporário no aparelho até concluir a importação.
• Serviços de mapa e otimização (ex.: tiles de mapa, OSRM) recebem apenas coordenadas/endereços necessários para calcular rotas quando você usa o plano PRO.

4. Permissões do Android
• Câmera: leitura de códigos de barras/QR de pacotes (opcional).
• Armazenamento/seletor de arquivos: importar planilha .xlsx.
• Localização: rota ativa e otimização com GPS.

5. Plano PRO e licença
A licença PRO é um código assinado, gerado pela DEV ALN e vinculado ao ID do aparelho. A validação é feita no próprio celular, sem envio a servidores externos.

6. Seus direitos
Você pode excluir rotas pelo app e desinstalar o aplicativo para remover dados locais. Para dúvidas sobre privacidade, use o canal de contato indicado na distribuição do APK.

7. Alterações
Podemos atualizar esta política; a data no topo indica a versão vigente.
''';

const _termsPt = '''
TERMOS DE USO — ROTA PRIME
Última atualização: setembro de 2026

1. Aceitação
Ao instalar e usar o ROTA PRIME, você concorda com estes termos. Se não concordar, não utilize o app.

2. Finalidade
O ROTA PRIME auxilia na organização de entregas. Você é responsável por cumprir leis de trânsito, regras da transportadora/marketplace e pela veracidade dos endereços importados.

3. Planos Gratuito e PRO
• Gratuito: importação, mapa, registro de entregas e ordem conforme a planilha, sem otimização automática de rota.
• PRO: inclui otimização de rota (OSRM), refinamento e recursos marcados como PRO no app, ativados por licença pessoal válida neste aparelho.

4. Licença PRO
A chave é pessoal e intransferível, salvo acordo com o licenciador. Compartilhar chaves publicamente pode resultar em revogação. A ativação é feita no dispositivo; “Cancelar assinatura” no app reverte para o plano Gratuito localmente.

5. Limitação de responsabilidade
Rotas sugeridas são auxiliares. Sempre confirme endereços, restrições de acesso e segurança ao dirigir. O desenvolvedor não se responsabiliza por atrasos, multas, perdas comerciais ou dados incorretos na planilha de terceiros.

6. Serviços de terceiros
Navegação externa (Waze, Google Maps), mapas online e APIs de rota são regidos pelos termos desses provedores.

7. Propriedade intelectual
Marca ROTA PRIME, interface e código pertencem ao licenciador. É proibida engenharia reversa para clonar o serviço ou contornar licenciamento PRO.

8. Rescisão
Você pode parar de usar o app a qualquer momento. Podemos descontinuar funcionalidades com aviso razoável nas atualizações.

9. Contato
Questões sobre estes termos: utilize o mesmo canal de suporte da distribuição do APK (DEV ALN).
''';
