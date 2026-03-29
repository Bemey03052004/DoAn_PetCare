using System.Net;
using System.Net.Mail;
using System.Text;

namespace PetCare.Services
{
public interface IEmailService
{
    Task SendEmailAsync(string to, string subject, string body, bool isHtml = true);
    Task SendPasswordResetEmailAsync(string to, string resetToken, string email);
    Task SendPasswordResetCodeAsync(string to, string resetCode);
    Task SendEmailVerificationAsync(string to, string verificationCode);
}

    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task SendEmailAsync(string to, string subject, string body, bool isHtml = true)
        {
            try
            {
                var smtpHost = _configuration["Email:SmtpHost"] ?? "smtp.gmail.com";
                var smtpPort = int.Parse(_configuration["Email:SmtpPort"] ?? "587");
                var smtpUsername = _configuration["Email:SmtpUsername"];
                var smtpPassword = _configuration["Email:SmtpPassword"];
                var fromEmail = _configuration["Email:FromEmail"] ?? smtpUsername;
                var fromName = _configuration["Email:FromName"] ?? "PetCare";

                if (string.IsNullOrEmpty(smtpUsername) || string.IsNullOrEmpty(smtpPassword))
                {
                    _logger.LogWarning("Email configuration is missing. Skipping email send to {Email}", to);
                    return;
                }

                using var client = new SmtpClient(smtpHost, smtpPort);
                client.EnableSsl = true;
                client.Credentials = new NetworkCredential(smtpUsername, smtpPassword);

                var message = new MailMessage();
                message.From = new MailAddress(fromEmail, fromName);
                message.To.Add(to);
                message.Subject = subject;
                message.Body = body;
                message.IsBodyHtml = isHtml;
                message.BodyEncoding = Encoding.UTF8;
                message.SubjectEncoding = Encoding.UTF8;

                await client.SendMailAsync(message);
                _logger.LogInformation("Email sent successfully to {Email}", to);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send email to {Email}", to);
                throw;
            }
        }

        public async Task SendPasswordResetEmailAsync(string to, string resetToken, string email)
        {
            var resetUrl = $"{_configuration["App:BaseUrl"]}/reset-password?token={resetToken}&email={Uri.EscapeDataString(email)}";
            
            var subject = "Đặt lại mật khẩu - PetCare";
            var body = $@"
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset='utf-8'>
                    <style>
                        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                        .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                        .button {{ display: inline-block; background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }}
                        .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 14px; }}
                    </style>
                </head>
                <body>
                    <div class='container'>
                        <div class='header'>
                            <h1>🐾 PetCare</h1>
                            <h2>Đặt lại mật khẩu</h2>
                        </div>
                        <div class='content'>
                            <p>Xin chào,</p>
                            <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản <strong>{email}</strong> của bạn.</p>
                            <p>Nhấp vào nút bên dưới để đặt lại mật khẩu:</p>
                            <p style='text-align: center;'>
                                <a href='{resetUrl}' class='button'>Đặt lại mật khẩu</a>
                            </p>
                            <p>Hoặc sao chép và dán liên kết này vào trình duyệt:</p>
                            <p style='word-break: break-all; background: #eee; padding: 10px; border-radius: 5px;'>{resetUrl}</p>
                            <p><strong>Lưu ý:</strong> Liên kết này sẽ hết hạn sau 1 giờ.</p>
                            <p>Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.</p>
                        </div>
                        <div class='footer'>
                            <p>Trân trọng,<br>Đội ngũ PetCare</p>
                        </div>
                    </div>
                </body>
                </html>";

        await SendEmailAsync(to, subject, body);
    }

    public async Task SendPasswordResetCodeAsync(string to, string resetCode)
    {
        var subject = "Mã đặt lại mật khẩu - PetCare";
        var body = $@"
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset='utf-8'>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                    .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                    .code {{ background: #667eea; color: white; padding: 15px; text-align: center; font-size: 24px; font-weight: bold; border-radius: 5px; margin: 20px 0; letter-spacing: 5px; }}
                    .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 14px; }}
                </style>
            </head>
            <body>
                <div class='container'>
                    <div class='header'>
                        <h1>🐾 PetCare</h1>
                        <h2>Đặt lại mật khẩu</h2>
                    </div>
                    <div class='content'>
                        <p>Xin chào,</p>
                        <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản <strong>{to}</strong> của bạn.</p>
                        <p>Để đặt lại mật khẩu, vui lòng sử dụng mã sau:</p>
                        <div class='code'>{resetCode}</div>
                        <p>Nhập mã này vào ứng dụng để tiếp tục đặt lại mật khẩu.</p>
                        <p><strong>Lưu ý:</strong> Mã này sẽ hết hạn sau 15 phút.</p>
                        <p>Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.</p>
                    </div>
                    <div class='footer'>
                        <p>Trân trọng,<br>Đội ngũ PetCare</p>
                    </div>
                </div>
            </body>
            </html>";

        await SendEmailAsync(to, subject, body);
    }

    public async Task SendEmailVerificationAsync(string to, string verificationCode)
        {
            var subject = "Xác thực email - PetCare";
            var body = $@"
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset='utf-8'>
                    <style>
                        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                        .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                        .code {{ background: #667eea; color: white; padding: 15px; text-align: center; font-size: 24px; font-weight: bold; border-radius: 5px; margin: 20px 0; letter-spacing: 5px; }}
                        .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 14px; }}
                    </style>
                </head>
                <body>
                    <div class='container'>
                        <div class='header'>
                            <h1>🐾 PetCare</h1>
                            <h2>Xác thực email</h2>
                        </div>
                        <div class='content'>
                            <p>Xin chào,</p>
                            <p>Cảm ơn bạn đã đăng ký tài khoản PetCare!</p>
                            <p>Để hoàn tất việc đăng ký, vui lòng sử dụng mã xác thực sau:</p>
                            <div class='code'>{verificationCode}</div>
                            <p>Nhập mã này vào ứng dụng để xác thực email của bạn.</p>
                            <p><strong>Lưu ý:</strong> Mã này sẽ hết hạn sau 15 phút.</p>
                            <p>Nếu bạn không đăng ký tài khoản này, vui lòng bỏ qua email này.</p>
                        </div>
                        <div class='footer'>
                            <p>Trân trọng,<br>Đội ngũ PetCare</p>
                        </div>
                    </div>
                </body>
                </html>";

            await SendEmailAsync(to, subject, body);
        }
    }
}
