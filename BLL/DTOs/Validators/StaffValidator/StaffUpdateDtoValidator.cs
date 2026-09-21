using BLL.DTOs.Staff;
using FluentValidation;

namespace BLL.DTOs.Validators.StaffValidator
{
    public class StaffUpdateDtoValidator : AbstractValidator<StaffUpdateDto>
    {
        public StaffUpdateDtoValidator()
        {
            RuleFor(x => x.FullName)
                .NotEmpty().WithMessage("Full name is required")
                .Length(3, 100).WithMessage("Full name must be between 3 and 100 characters");

            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required")
                .EmailAddress().WithMessage("Invalid email address");

            RuleFor(x => x.Role)
                .IsInEnum().WithMessage("Invalid role");

            RuleFor(x => x.IsActive)
                .NotNull();
        }
    }
}