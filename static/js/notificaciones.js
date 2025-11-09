// Script global para auto-eliminar notificaciones de Bootstrap
document.addEventListener('DOMContentLoaded', function() {
    // Auto-eliminar alertas de Bootstrap después de 20 segundos
    const alerts = document.querySelectorAll('.alert:not(.alert-permanent)');
    
    alerts.forEach(function(alert) {
        // Solo aplicar a alertas que no tienen la clase 'alert-permanent'
        if (!alert.classList.contains('alert-permanent')) {
            setTimeout(function() {
                // Usar Bootstrap para hacer fade out suave
                if (alert && alert.parentNode) {
                    const bsAlert = new bootstrap.Alert(alert);
                    if (bsAlert) {
                        bsAlert.close();
                    } else {
                        // Fallback si Bootstrap no está disponible
                        alert.style.transition = 'opacity 0.5s ease-out';
                        alert.style.opacity = '0';
                        setTimeout(() => {
                            if (alert.parentNode) {
                                alert.remove();
                            }
                        }, 500);
                    }
                }
            }, 20000); // 20 segundos
        }
    });
});

// Función global para crear notificaciones temporales
function mostrarNotificacionTemporal(mensaje, tipo = 'info', duracion = 20000) {
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${tipo} alert-dismissible fade show position-fixed`;
    alertDiv.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px; max-width: 500px;';
    alertDiv.innerHTML = `
        ${mensaje}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `;
    
    document.body.appendChild(alertDiv);
    
    // Auto-remove después del tiempo especificado
    setTimeout(() => {
        if (alertDiv.parentNode) {
            const bsAlert = new bootstrap.Alert(alertDiv);
            if (bsAlert) {
                bsAlert.close();
            } else {
                alertDiv.remove();
            }
        }
    }, duracion);
    
    return alertDiv;
}