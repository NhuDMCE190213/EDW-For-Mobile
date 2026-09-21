using AutoMapper;
using BLL.DTOs.CartItem;
using BLL.DTOs.Product.Customer;
using BLL.DTOs.ProductVariant.Customer;
using BLL.DTOs.ProductVariant.Staff;
using BLL.DTOs.Promotion;
using DAL.Models;

namespace BLL.Settings
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            CreateMap<Promotion, PromotionDto>().ReverseMap();
            CreateMap<CartItem, CartItemDTO>();
            CreateMap<ProductVariant, CartItemProductVariantDto>()
                .ForMember(dest => dest.ProductName, opt => opt.MapFrom(src => src.Product!.ProductName))
                .ForMember(dest => dest.Brand, opt => opt.MapFrom(src => src.Product!.Brand));

            CreateMap<ProductVariant, ProductVariantStaffDto>();
            CreateMap<ProductVariant, ProductVariantStaffCreateDto>();
            CreateMap<ProductVariant, ProductVariantCustomerDto>();

            CreateMap<Product, ProductCustomerDto>()
                .ForMember(dest => dest.CategoryName, opt => opt.MapFrom(src => src.Category != null ? src.Category.Name : string.Empty))
                .ForMember(dest => dest.ProductVariants, opt => opt.MapFrom(src => src.ProductVariants));
        }
    }
}
