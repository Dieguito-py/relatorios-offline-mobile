# 🔧 Guia de Configuração de API - Defesa Civil Mobile

## ❌ Problema: Connection Refused

Se você está recebendo o erro:
```
ClientException with SocketException: Connection refused
```

Isso significa que o app não consegue conectar ao backend em `localhost:8084`.

## ✅ Soluções

### 1. **Verificar se o Backend está rodando**

Certifique-se de que o seu backend Spring Boot está:
- ✅ Rodando na porta 8084
- ✅ Acessível na rede local

Teste no navegador ou Postman:
```
POST http://localhost:8084/api/auth/login
Content-Type: application/json

{
  "username": "teste",
  "password": "1234"
}
```

### 2. **Configurar IP correto no app**

O app agora tem uma tela de configurações! 

#### Para Android Emulator:
1. Abra o app
2. Clique no ícone de ⚙️ **Configurações** na tela de login
3. Digite o IP: `10.0.2.2`
4. Porta: `8084`
5. Clique em **Salvar Configuração**

> **Por quê 10.0.2.2?** O emulador Android mapeia `10.0.2.2` para o `localhost` do computador host.

#### Para Dispositivo Físico Android/iOS:
1. Descubra o IP da sua máquina:
   - Windows: `ipconfig` (procure por IPv4)
   - Linux/Mac: `ifconfig` ou `ip addr`
   - Exemplo: `192.168.1.100`

2. Configure no app:
   - IP: `192.168.1.100` (seu IP real)
   - Porta: `8084`

3. **IMPORTANTE:** Certifique-se de que:
   - O dispositivo está na mesma rede Wi-Fi que o computador
   - O firewall permite conexões na porta 8084

#### Para Windows Desktop:
- Deixe os campos vazios para usar `localhost` automaticamente

### 3. **Configurar CORS no Backend Spring Boot**

Se o erro persistir, adicione configuração de CORS no backend:

```java
@Configuration
public class WebConfig {
    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                    .allowedOrigins("*")
                    .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                    .allowedHeaders("*");
            }
        };
    }
}
```

### 4. **Testar a Conexão**

Depois de configurar:
1. Volte para a tela de login
2. Tente fazer login novamente
3. Verifique os logs no console (Debug Console)

Os logs mostrarão:
```
🔵 Tentando login para: teste
🔵 URL: http://10.0.2.2:8084/api/auth/login
🔵 Platform: android
🔵 Request Body: {"username":"teste","password":"1234"}
📥 Status Code: 200
✅ Token recebido: eyJhbGciOiJIUzI1Ni...
```

## 🐛 Debug

### Ver logs detalhados:
1. Abra o terminal/console do Flutter
2. Todos os logs estão com emojis para facilitar:
   - 🔵 Informação
   - ✅ Sucesso
   - ❌ Erro

### Testar manualmente a requisição:

Use o arquivo de teste criado:
```bash
dart test/test_api_connection.dart
```

## 📱 Plataformas

| Plataforma | IP Padrão | Observações |
|---|---|---|
| Android Emulator | `10.0.2.2` | Mapeia para localhost do host |
| iOS Simulator | `localhost` | Funciona diretamente |
| Dispositivo Físico | `192.168.x.x` | IP real da máquina na rede |
| Windows Desktop | `localhost` | Padrão |

## 🚀 Dicas

1. **Sempre teste o backend primeiro** com Postman/Insomnia
2. **Use a tela de configurações** para facilitar mudanças de IP
3. **Verifique o firewall** se usar dispositivo físico
4. **Mesma rede Wi-Fi** é essencial para dispositivos físicos

## 💡 Recursos Adicionados

- ✅ Tela de configurações de API (ícone ⚙️ no login)
- ✅ Detecção automática de plataforma
- ✅ Logs detalhados para debug
- ✅ Timeout de 10 segundos nas requisições
- ✅ Mensagens de erro claras

---

**Precisa de ajuda?** Verifique os logs do console para mais detalhes!

