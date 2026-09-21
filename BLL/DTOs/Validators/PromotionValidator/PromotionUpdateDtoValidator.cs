using BLL.DTOs.Promotion;
using DAL.Enums;
using FluentValidation;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.DTOs.Validators.PromotionValidator
{
    public class PromotionUpdateDtoValidator : AbstractValidator<PromotionUpdateDto>
    {
        public PromotionUpdateDtoValidator()
        {

            // Name
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Promotion name is required")
                .Length(3, 100).WithMessage("Promotion name must be between 3 and 100 characters");

            // Type
            RuleFor(x => x.PromotionType)
                .IsInEnum().WithMessage("Invalid promotion type");

            // Percentage
            When(x => x.PromotionType == PromotionTypeEnum.Percentage, () =>
            {
                RuleFor(x => x.Percentage)
                    .NotNull().WithMessage("Percentage is required for Percentage type")
                    .InclusiveBetween((byte)0, (byte)100).WithMessage("Percentage must be between 0 and 100");
            });

            // Price
            When(x => x.PromotionType == PromotionTypeEnum.FixedAmount, () =>
            {
                RuleFor(x => x.SalePrice)
                    .NotNull().WithMessage("Sale price is required for Fixed Amount type")
                    .GreaterThanOrEqualTo(0).WithMessage("Sale price must be greater than or equal to 0");

                RuleFor(x => x.ThresholdPrice)
                    .NotNull().WithMessage("Threshold price is required for Fixed Amount type")
                    .GreaterThanOrEqualTo(0).WithMessage("Threshold price must be greater than or equal to 0")
                    .GreaterThanOrEqualTo(x => x.SalePrice)
                    .When(x => x.SalePrice.HasValue && x.ThresholdPrice.HasValue)
                    .WithMessage("Threshold price must be greater than or equal to sale price");
            });

            // Validate Time
            When(x => x.IsLimitedTime, () =>
            {
                RuleFor(x => x.StartAt)
                    .NotNull().WithMessage("Start date is required when limited time is enabled");

                RuleFor(x => x.EndAt)
                    .NotNull().WithMessage("End date is required when limited time is enabled")
                    .GreaterThan(x => x.StartAt!.Value)
                    .When(x => x.StartAt.HasValue)
                    .WithMessage("End date must be after start date");

                // Optional: Check if end date is not in the past (for update, might want to allow past dates if promotion is already active)
                RuleFor(x => x.EndAt)
                    .GreaterThan(DateTime.Now)
                    .When(x => x.EndAt.HasValue)
                    .WithMessage("End date cannot be in the past");
            });

            // Validate Stock
            When(x => x.IsReservedStock, () =>
            {
                RuleFor(x => x.MaxReservedStock)
                    .NotNull().WithMessage("Max reserved stock is required when reserved stock is enabled")
                    .GreaterThan(0).WithMessage("Max reserved stock must be greater than 0");
            });

            // Must have at least one option
            RuleFor(x => x)
                .Must(x => x.IsLimitedTime || x.IsReservedStock)
                .WithMessage("Please select at least one option: Limited Time or Reserved Stock.");
        }
    }
}