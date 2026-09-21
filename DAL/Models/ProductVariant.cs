using DAL.Enums;
using DAL.Models.Base;
using DAL.Utilities;

namespace DAL.Models
{
    public class ProductVariant : IBaseEntity
    {
        public Guid ProductVariantId { get; set; }
        //public string ProductCode { get; set; } = string.Empty;
        public string Sku { get; set; } = string.Empty;
        public string Color { get; set; } = string.Empty;
        public string? Cpu { get; set; }
        public string? Ram { get; set; }
        public string? Storage { get; set; }
        public string? ScreenSize { get; set; }
        public decimal Price { get; set; }
        public int StockQuantity { get; set; }
        public string? ImageUrl { get; set; }
        public int ProductId { get; set; }
        virtual public Product? Product { get; set; }

        public bool IsDeleted { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public Guid? PromotionId { get; set; } = null;
        virtual public Promotion? Promotion { get; set; }


        public static ProductVariant Create(
            //string productCode,
            string color,
            string? cpu,
            string? ram,
            string? storage,
            string? screenSize,
            decimal price,
            int stockQuantity,
            string? imageUrl,
            int productId, Guid? promotionId)
        {
            if (price < 0)
                throw new ArgumentException("Price cannot be negative.", nameof(price));
            if (stockQuantity < 0)
                throw new ArgumentException("Stock quantity cannot be negative.", nameof(stockQuantity));

            string sku = SkuGenerator.Generate(productId, color, cpu, ram, storage, screenSize);

            var productVariant = new ProductVariant
            {
                //ProductCode = productCode,
                Sku = sku,
                Color = color,
                Cpu = cpu,
                Ram = ram,
                Storage = storage,
                ScreenSize = screenSize,
                Price = price,
                StockQuantity = stockQuantity,
                ImageUrl = imageUrl,
                ProductId = productId,
                PromotionId = promotionId,
                CreatedAt = DateTime.UtcNow
            };
            return productVariant;
        }

        public static ProductVariant Create(
            //string productCode, 
            string color, 
            string? cpu, 
            string? ram, 
            string? storage, 
            string? screenSize, 
            decimal price, 
            int stockQuantity, 
            string? imageUrl, 
            int productId)
        {
            if (price < 0)
                throw new ArgumentException("Price cannot be negative.", nameof(price));
            if (stockQuantity < 0)
                throw new ArgumentException("Stock quantity cannot be negative.", nameof(stockQuantity));

            string sku = SkuGenerator.Generate(productId, color, cpu, ram, storage, screenSize);

            var productVariant = new ProductVariant
            {
                //ProductCode = productCode,
                Sku = sku,
                Color = color,
                Cpu = cpu,
                Ram = ram,
                Storage = storage,
                ScreenSize = screenSize,
                Price = price,
                StockQuantity = stockQuantity,
                ImageUrl = imageUrl,
                ProductId = productId,
                CreatedAt = DateTime.UtcNow
            };
            return productVariant;
        }

        public void Update(
            //string productCode, 
            string color, 
            string? cpu, 
            string? ram, 
            string? storage, 
            string? screenSize, 
            decimal price, 
            int stockQuantity, 
            string? imageUrl, 
            int productId)
        {
            if (price < 0)
                throw new ArgumentException("Price cannot be negative.", nameof(price));
            if (stockQuantity < 0)
                throw new ArgumentException("Stock quantity cannot be negative.", nameof(stockQuantity));

            string sku = SkuGenerator.Generate(productId, color, cpu, ram, storage, screenSize);

            Sku = sku;
            //ProductCode = productCode;
            Color = color;
            Cpu = cpu;
            Ram = ram;
            Storage = storage;
            ScreenSize = screenSize;
            Price = price;
            StockQuantity = stockQuantity;
            ImageUrl = imageUrl;
            ProductId = productId;
            UpdatedAt = DateTime.UtcNow;
        }

        public void Update(
            //string productCode, 
            string color, 
            string? cpu, 
            string? ram, 
            string? storage, 
            string? screenSize, 
            decimal price, 
            int stockQuantity, 
            string? imageUrl, 
            int productId, Guid? promotionId)
        {
            if (price < 0)
                throw new ArgumentException("Price cannot be negative.", nameof(price));
            if (stockQuantity < 0)
                throw new ArgumentException("Stock quantity cannot be negative.", nameof(stockQuantity));

            string sku = SkuGenerator.Generate(productId, color, cpu, ram, storage, screenSize);

            Sku = sku;
            Color = color;
            Cpu = cpu;
            Ram = ram;
            Storage = storage;
            ScreenSize = screenSize;
            Price = price;
            StockQuantity = stockQuantity;
            ImageUrl = imageUrl;
            ProductId = productId;
            PromotionId = promotionId;
            UpdatedAt = DateTime.UtcNow;
        }

        public void Delete()
        {
            IsDeleted = true;
            UpdatedAt = DateTime.UtcNow;
        }

        public void StockIn(int increaseAmount)
        {
            if (increaseAmount < 0)
                throw new ArgumentException("The stock increase amount cannot be negative.", nameof(increaseAmount));

            StockQuantity += increaseAmount;
            UpdatedAt = DateTime.UtcNow;
        }

        public decimal GetPrice() 
        {
            if (Promotion != null && Promotion.IsActive())
            {
                if (Promotion.PromotionType == PromotionTypeEnum.Percentage && Promotion.Percentage.HasValue)
                {
                    return Price * (1 - Promotion.Percentage.Value / 100m);
                }
                else if (Promotion.PromotionType == PromotionTypeEnum.FixedAmount && Promotion.SalePrice.HasValue)
                {
                    return Price - Promotion.SalePrice.Value;
                }
            }

            return Price;
        }
    }
}
