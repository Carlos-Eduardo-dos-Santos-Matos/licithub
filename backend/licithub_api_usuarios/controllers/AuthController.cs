using System.Security.Claims;
using licithub_api_usuarios.Dtos;
using licithub_api_usuarios.Models;
using licithub_api_usuarios.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace licithub_api_usuarios.Controllers;

[ApiController]
[Route("api/auth")]
public sealed class AuthController(IAuthService authService) : ControllerBase
{
    [HttpPost("registrar")]
    [AllowAnonymous]
    [ProducesResponseType<UsuarioResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<UsuarioResponse>> Registrar(
        RegistrarUsuarioRequest request,
        CancellationToken cancellationToken)
    {
        var usuario = await authService.RegistrarAsync(request, cancellationToken);
        return CreatedAtAction(nameof(ObterAtual), null, usuario);
    }

    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType<TokenResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<TokenResponse>> Login(
        LoginRequest request,
        CancellationToken cancellationToken)
    {
        var tokens = await authService.LoginAsync(request, cancellationToken);
        return tokens is null
            ? Unauthorized(new ProblemDetails
            {
                Status = StatusCodes.Status401Unauthorized,
                Title = "Não autorizado",
                Detail = "E-mail ou senha inválidos."
            })
            : Ok(tokens);
    }

    [HttpPost("refresh")]
    [AllowAnonymous]
    [ProducesResponseType<TokenResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<TokenResponse>> Refresh(
        RefreshTokenRequest request,
        CancellationToken cancellationToken)
    {
        var tokens = await authService.RenovarTokenAsync(request, cancellationToken);
        return tokens is null
            ? Unauthorized(new ProblemDetails
            {
                Status = StatusCodes.Status401Unauthorized,
                Title = "Não autorizado",
                Detail = "Refresh token inválido ou expirado."
            })
            : Ok(tokens);
    }

    [HttpGet("me")]
    [Authorize]
    [ProducesResponseType<UsuarioResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<UsuarioResponse>> ObterAtual(CancellationToken cancellationToken)
    {
        var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!long.TryParse(claim, out var usuarioId))
            return Unauthorized();

        var usuario = await authService.ObterAsync(usuarioId, cancellationToken);
        return usuario is null ? NotFound() : Ok(usuario);
    }

    [HttpPost("logout")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Logout(CancellationToken cancellationToken)
    {
        var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!long.TryParse(claim, out var usuarioId))
            return Unauthorized();

        await authService.RevogarTokenAsync(usuarioId, cancellationToken);
        return NoContent();
    }
}
