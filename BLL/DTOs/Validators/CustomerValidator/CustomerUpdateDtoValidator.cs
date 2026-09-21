using BLL.DTOs.Customer;
using FluentValidation;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.DTOs.Validators.CustomerValidator
{
    public class CustomerUpdateDtoValidator : AbstractValidator<CustomerUpdateDto>
    {
        public CustomerUpdateDtoValidator()
        {
            RuleFor(x => x.FullName)
                .NotEmpty().WithMessage("Full name is required")
                .Length(2, 255).WithMessage("Full name must be between 2 and 255 characters");

            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required")
                .EmailAddress().WithMessage("Invalid email address");

            RuleFor(x => x.PhoneNumber)
                .NotEmpty().WithMessage("Phone number is required")
                .Matches(@"^\+?[0-9]{7,15}$").WithMessage("Phone must be numeric and between 7 and 15 digits");

            RuleFor(x => x.Role)
                .NotNull().WithMessage("Role is required")
                .IsInEnum().WithMessage("Please select a valid role");

            RuleFor(x => x.Points)
                .GreaterThanOrEqualTo(0).WithMessage("Points must be greater than or equal to 0");
        }
    }
}
