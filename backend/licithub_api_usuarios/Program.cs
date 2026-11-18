using System.Data;
using System.Text;
using licithub_api_usuarios.Configuration;
using licithub_api_usuarios.Data;
using licithub_api_usuarios.Middleware;
using licithub_api_usuarios.Models;
using licithub_api_usuarios.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using MySqlConnector;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddPolicy("Frontend", policy =>
    {
        policy.SetIsOriginAllowed(origem =>
            Uri.TryCreate(origem, UriKind.Absolute, out var uri) && uri.IsLoopback)
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

builder.Services.AddOpenApi();
builder.Services.AddControllers();
builder.Services.AddProblemDetails();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("ConnectionStrings:DefaultConnection não configurada.");

builder.Services.AddDbContext<ContextoBanco>(options =>
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));

builder.Services.AddOptions<JwtOptions>()
    .Bind(builder.Configuration.GetSection(JwtOptions.SectionName))
    .Validate(options => !string.IsNullOrWhiteSpace(options.Key) && options.Key.Length >= 32,
        "Jwt:Key deve possuir pelo menos 32 caracteres.")
    .ValidateOnStart();

var jwtConfiguration = builder.Configuration.GetSection(JwtOptions.SectionName);
var jwtKey = jwtConfiguration["Key"]!;

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ValidateIssuer = true,
            ValidIssuer = jwtConfiguration["Issuer"] ?? "licithub",
            ValidateAudience = true,
            ValidAudience = jwtConfiguration["Audience"] ?? "licithub",
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30)
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddExceptionHandler<ApiExceptionHandler>();

var app = builder.Build();

await GarantirAdminPadraoAsync(app);

if (app.Environment.IsDevelopment())
    app.MapOpenApi();
else
    app.UseHttpsRedirection();

app.UseExceptionHandler();
app.UseCors("Frontend");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

static async Task GarantirAdminPadraoAsync(WebApplication app)
{
    const string emailAdmin = "admin@licithub.com";
    const string senhaAdmin = "Admin@123";
    const string cnpjAdmin = "00000000000191";
    const string razaoAdmin = "LicitHub Admin LTDA";

    try
    {
        using var scope = app.Services.CreateScope();
        var contexto = scope.ServiceProvider.GetRequiredService<ContextoBanco>();

        var usuario = await contexto.Usuarios.SingleOrDefaultAsync(u => u.Email == emailAdmin);
        if (usuario is null)
        {
            usuario = new Usuario
            {
                Nome = "Administrador LicitHub",
                Email = emailAdmin,
                HashSenha = BCrypt.Net.BCrypt.HashPassword(senhaAdmin),
                DataCriacao = DateTime.UtcNow,
                Ativo = true
            };
            contexto.Usuarios.Add(usuario);
            await contexto.SaveChangesAsync();
        }

        var conn = (MySqlConnection)contexto.Database.GetDbConnection();
        if (conn.State != ConnectionState.Open)
            await conn.OpenAsync();

        await using var cmdEmpresa = conn.CreateCommand();
        cmdEmpresa.CommandText = @"
            INSERT INTO tb_empresas (nr_cnpj, nm_razao_social, tp_porte)
            VALUES (@Cnpj, @RazaoSocial, 'EPP')
            ON DUPLICATE KEY UPDATE nm_razao_social = VALUES(nm_razao_social);
            SELECT id_empresa FROM tb_empresas WHERE nr_cnpj = @Cnpj LIMIT 1;";
        cmdEmpresa.Parameters.AddWithValue("@Cnpj", cnpjAdmin);
        cmdEmpresa.Parameters.AddWithValue("@RazaoSocial", razaoAdmin);

        var idEmpresa = Convert.ToInt64(await cmdEmpresa.ExecuteScalarAsync());

        await using var cmdVinculo = conn.CreateCommand();
        cmdVinculo.CommandText = @"
            INSERT INTO tb_empresas_usuarios (id_empresa, id_usuario, tp_papel, st_vinculo)
            VALUES (@IdEmpresa, @IdUsuario, 'ADMIN', 'ATIVO')
            ON DUPLICATE KEY UPDATE st_vinculo = 'ATIVO', tp_papel = 'ADMIN';";
        cmdVinculo.Parameters.AddWithValue("@IdEmpresa", idEmpresa);
        cmdVinculo.Parameters.AddWithValue("@IdUsuario", usuario.Id);
        await cmdVinculo.ExecuteNonQueryAsync();
    }
    catch (Exception ex)
    {
        app.Logger.LogWarning(ex, "Não foi possível criar o usuário admin padrão na inicialização.");
    }
}