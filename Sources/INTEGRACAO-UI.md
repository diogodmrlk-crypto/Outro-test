# Integração mantendo o layout original

A UI atual pode continuar com o mesmo layout, cores, abas e botões. A integração abaixo substitui somente as ações ligadas ao executor antigo.

## 1. Imports

Em `SporkUI.mm`, remova os imports de `exploit.hpp`, `hooks.hpp` e `memory.hpp`. Use:

```objc
#import "execution.hpp"
#import "ScriptStore.h"
#import "SporkLogStore.h"
```

Remova também `extern void* ExploitThread;`.

## 2. Logs

Substitua o armazenamento global `g_logs` e a implementação antiga de `SporkLog` por:

```objc
void SporkLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    SporkLogAppend(message);
}
```

No método `updateLogs`, use:

```objc
self.logsTextView.text = [SporkLogSnapshot() componentsJoinedByString:@"\\n"];
```

## 3. Botão Execute

Substitua `runScriptString:` por:

```objc
- (void)runScriptString:(NSString *)script {
    if (script.length == 0) {
        SporkLog(@"Editor vazio.");
        return;
    }

    NSString *source = [script copy];
    SporkLog(@"Compilando e executando Luau localmente...");

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        std::string output;
        int result = ExecuteScript(std::string(source.UTF8String ?: ""), output);

        NSString *message = [NSString stringWithUTF8String:output.c_str()];
        SporkLog(@"%@", message ?: @"Execução finalizada.");

        if (result == 0) {
            SporkLog(@"[OK] Execução concluída.");
        } else {
            SporkLog(@"[ERRO] Código %d", result);
        }
    });
}
```

O método `executeScriptAction` pode permanecer como está.

## 4. Botão de injeção / Home

O método `injectExecutorAction` não deve chamar `SetupExploit`. Substitua o corpo por uma mensagem informativa:

```objc
- (void)injectExecutorAction {
    self.statusLabel.text = @"Luau local pronto";
    self.statusLabel.textColor = [UIColor greenColor];
    [self.injectBtn setTitle:@"VM Ready" forState:UIControlStateNormal];
    self.injectBtn.enabled = NO;
    SporkLog(@"VM Luau independente pronta. Nenhum processo externo será acessado.");
}
```

Se a aba Home tiver texto “Inject Executor”, altere apenas o texto para “Iniciar VM Luau”. Não altere as constraints ou o desenho da tela.

## 5. Salvar e carregar scripts

A classe `ScriptStore` já salva e carrega arquivos `.luau` em `Documents/SporkScripts`. Exemplo para ligar a um botão existente:

```objc
NSError *error = nil;
BOOL ok = [[ScriptStore sharedStore] saveScriptNamed:@"MeuScript"
                                             content:self.scriptEditor.text
                                               error:&error];
SporkLog(ok ? @"Script salvo." : @"Falha ao salvar: %@", error.localizedDescription);
```

Para carregar:

```objc
NSString *source = [[ScriptStore sharedStore] loadScriptNamed:@"MeuScript" error:&error];
if (source) self.scriptEditor.text = source;
```

Para listar nomes:

```objc
NSArray<NSString *> *names = [[ScriptStore sharedStore] allScriptNames];
```

Para excluir:

```objc
[[ScriptStore sharedStore] deleteScriptNamed:@"MeuScript" error:&error];
```

## 6. Remover código antigo do target

Remova do `Makefile` as fontes `exploit.mm`, `hooks.mm`, `memory.cpp`, `Tweak.xm` e quaisquer referências a `config.hpp`, `ptrauth.h` ou offsets. Não apague os arquivos do repositório até confirmar que nenhuma outra parte os usa.

**Nota:** o target atual é um tweak. A UI do repositório foi desenhada como overlay. A migração para app independente precisa de um `AppDelegate`/`main.m` e target `app.mk`; este pacote não declara que essa conversão completa já foi feita ou testada.
