# Zé Palitos — Protótipo 0.1

Protótipo 3D pequeno feito com Godot 4.x e GDScript. O mapa, o boneco palito, as armas e os alvos usam formas primitivas geradas pelo próprio projeto; não há dependências externas.

## Abrir e executar

1. Instale o Godot 4.x.
2. No Project Manager, escolha **Importar** e selecione este diretório ou abra `project.godot`.
3. Execute com **F6/F5** ou pelo botão **Executar Projeto**. O renderizador está configurado como **Compatibility**.

## Controles

### PC

- **WASD:** andar.
- **Ctrl:** correr.
- **Espaço:** pular.
- **Mouse:** olhar; no PC o cursor é capturado ao iniciar. Na versão Web, clique no jogo para capturá-lo; **Esc** libera ou recaptura o cursor.
- **Shift:** alternar Shift Lock.
- **Botão esquerdo do mouse:** atirar (segure para disparo automático do rifle).
- **E:** pegar a arma mais próxima.
- **1 / 2:** selecionar pistola / rifle já coletados.
- **Esc:** liberar ou recapturar o cursor.

As armas estão no chão, perto do início. A pistola causa 20 de dano por tiro e o rifle, 10. A munição é infinita.

### Android

O projeto solicita orientação paisagem e mostra joystick virtual, área de arraste para câmera e botões de pulo, tiro, Shift Lock, coleta e troca de arma em dispositivos com tela de toque. Os controles recebem toques independentes para permitir movimentação, câmera e ações simultâneas.

## Exportação

### Windows

No Godot, abra **Projeto > Exportar**, instale os templates de exportação solicitados e adicione um preset **Windows Desktop**. Exporte o executável para uma pasta de sua escolha.

### Android

Instale e configure o OpenJDK e o Android SDK no editor Godot. Em **Projeto > Exportar**, adicione o preset **Android**, configure as ferramentas SDK/JDK e exporte. A instalação de ferramentas e a assinatura para distribuição precisam ser feitas no ambiente de exportação.

### Web

Godot 4 pode exportar para Web em navegadores compatíveis. Instale os templates, adicione um preset **Web** e exporte os arquivos HTML/WebAssembly. Para testar, sirva a pasta exportada por um servidor HTTP local; não é necessário usar Vercel. Compatibilidade, desempenho e controles em navegadores móveis ainda dependem de validação no navegador-alvo.

## Organização

- `project.godot`: configuração e cena inicial.
- `scenes/`: cena principal, personagem, mapa, alvo, coleta de armas e HUD.
- `scripts/`: montagem procedural, movimentação/câmera, armas, alvos e interface.

## Testes e limitações conhecidas

- A sintaxe dos scripts GDScript foi validada com `gdparse`; as referências `res://` foram verificadas.
- O projeto foi aberto e executado pelo Godot 4.7.2 em modo headless, sem erros de inicialização.
- A exportação Web foi gerada e carregada no navegador; a cena e o HUD renderizaram sem erros JavaScript.
- A movimentação/interação em jogo e os controles touch em um celular ainda precisam de teste manual.
- A exportação Windows e Android não foi gerada; somente a exportação Web foi testada.
