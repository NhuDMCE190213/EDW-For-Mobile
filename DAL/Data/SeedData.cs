using DAL.Models;
using DAL.Enums;
using Microsoft.EntityFrameworkCore;

namespace DAL.Data
{
    public static class SeedData
    {
        public static void EnsureSeedData(this AppDbContext context)
        {
            // apply any pending migrations (safe for development/test)
            context.Database.Migrate();

            // ==================== Categories (4) ====================
            if (!context.Categories.Any())
            {
                var laptops = Category.Create("Laptops");
                var smartphones = Category.Create("Smartphones");
                var accessories = Category.Create("Accessories");
                var tablets = Category.Create("Tablets");
                context.Categories.AddRange(laptops, smartphones, accessories, tablets);
                context.SaveChanges();
            }

            // ==================== Products (12) ====================
            if (!context.Products.Any())
            {
                var catLaptop = context.Categories.First(c => c.Name == "Laptops");
                var catPhone = context.Categories.First(c => c.Name == "Smartphones");
                var catAccessory = context.Categories.First(c => c.Name == "Accessories");
                var catTablet = context.Categories.First(c => c.Name == "Tablets");

                var products = new[]
                {
                    Product.Create("XtremeBook 14", "ElectroNexus", catLaptop.Id, null),
                    Product.Create("XtremeBook 16", "ElectroNexus", catLaptop.Id, null),
                    Product.Create("UltraBook Air 13", "ElectroNexus", catLaptop.Id, null),
                    Product.Create("GamerBook X15", "ProTech", catLaptop.Id, null),
                    Product.Create("PocketPhone Z", "ElectroNexus", catPhone.Id, null),
                    Product.Create("PocketPhone Pro", "ElectroNexus", catPhone.Id, null),
                    Product.Create("PocketPhone Mini", "ElectroNexus", catPhone.Id, null),
                    Product.Create("SoundBuds Pro", "AudioTech", catAccessory.Id, null),
                    Product.Create("PowerBank 20000", "ChargeMaster", catAccessory.Id, null),
                    Product.Create("WirelessCharger Pad", "ChargeMaster", catAccessory.Id, null),
                    Product.Create("TabPro 11", "ElectroNexus", catTablet.Id, null),
                    Product.Create("TabLite 8", "ViewMax", catTablet.Id, null),
                };

                context.Products.AddRange(products);
                context.SaveChanges();
            }

            // ==================== ProductVariants (18) ====================
            if (!context.ProductVariants.Any())
            {
                var prod1 = context.Products.First(p => p.ProductName == "XtremeBook 14");
                var prod2 = context.Products.First(p => p.ProductName == "XtremeBook 16");
                var prod3 = context.Products.First(p => p.ProductName == "PocketPhone Z");
                var prod4 = context.Products.First(p => p.ProductName == "PocketPhone Pro");
                var prod5 = context.Products.First(p => p.ProductName == "SoundBuds Pro");
                var prod6 = context.Products.First(p => p.ProductName == "PowerBank 20000");
                var prod7 = context.Products.First(p => p.ProductName == "TabPro 11");
                var prod8 = context.Products.First(p => p.ProductName == "UltraBook Air 13");
                var prod9 = context.Products.First(p => p.ProductName == "GamerBook X15");
                var prod10 = context.Products.First(p => p.ProductName == "PocketPhone Mini");
                var prod11 = context.Products.First(p => p.ProductName == "WirelessCharger Pad");
                var prod12 = context.Products.First(p => p.ProductName == "TabLite 8");

                var variants = new[]
                {
                    // 0-1: XtremeBook 14
                    ProductVariant.Create("Black", "Intel i5", "8GB", "256GB", "14\"", 10000000, 30, null, prod1.ProductId),
                    ProductVariant.Create("Silver", "Intel i7", "16GB", "512GB", "14\"", 12999999, 15, null, prod1.ProductId),

                    // 2: XtremeBook 16
                    ProductVariant.Create("Black", "Intel i9", "32GB", "1TB", "16\"", 18999999, 10, null, prod2.ProductId),
                    // 3-4: PocketPhone Z
                    ProductVariant.Create("Silver", "ARM Octa", "6GB", "128GB", "6.1\"", 6999999, 80, null, prod3.ProductId),
                    ProductVariant.Create("Black", "ARM Octa", "8GB", "256GB", "6.1\"", 7999999, 50, null, prod3.ProductId),

                    // 5-6: PocketPhone Pro
                    ProductVariant.Create("Black", "ARM Octa Pro", "8GB", "256GB", "6.7\"", 9999999, 40, null, prod4.ProductId),
                    ProductVariant.Create("Silver", "ARM Octa Pro", "12GB", "512GB", "6.7\"", 11999999, 25, null, prod4.ProductId),
                    // 7-8: SoundBuds Pro
                    ProductVariant.Create("Black", null, null, null, null, 1499999, 100, null, prod5.ProductId),
                    ProductVariant.Create("White", null, null, null, null, 1499999, 80, null, prod5.ProductId),
                    // 9: PowerBank 20000
                    ProductVariant.Create("Black", null, null, null, null, 599999, 200, null, prod6.ProductId),

                    // 10: TabPro 11
                    ProductVariant.Create("Silver", "ARM Pro", "8GB", "128GB", "11\"", 499999, 30, null, prod7.ProductId),

                    // 11-12: UltraBook Air 13
                    ProductVariant.Create("Silver", "Intel i5", "8GB", "256GB", "13\"", 1099999, 20, null, prod8.ProductId),
                    ProductVariant.Create("Space Gray", "Intel i7", "16GB", "512GB", "13\"", 1399999, 12, null, prod8.ProductId),
                    // 13-14: GamerBook X15
                    ProductVariant.Create("Black", "Intel i7", "16GB", "512GB", "15\"", 15999999, 8, null, prod9.ProductId),
                    ProductVariant.Create("Black", "Intel i9", "32GB", "1TB", "15\"", 19999999, 5, null, prod9.ProductId),

                    // 15: PocketPhone Mini
                    ProductVariant.Create("White", "ARM Hexa", "6GB", "128GB", "5.4\"", 5999999, 35, null, prod10.ProductId),
                    // 16: WirelessCharger Pad
                    ProductVariant.Create("White", null, null, null, null, 39999, 150, null, prod11.ProductId),

                    // 17: TabLite 8
                    ProductVariant.Create("Gray", "ARM Lite", "4GB", "64GB", "8\"", 299999, 45, null, prod12.ProductId),
                };

                context.ProductVariants.AddRange(variants);
                context.SaveChanges();
            }

            // ==================== Promotions (10) ====================
            if (!context.Promotions.Any())
            {
                var variants = context.ProductVariants.ToList();
                var now = DateTime.UtcNow;

                var promotions = new List<Promotion>();

                // 1. Active - Percentage Discount (Flash Sale)
                promotions.Add(new Promotion().Create(
                    "Active - Percentage Discount (Flash Sale)",
                    PromotionTypeEnum.Percentage,
                    percentage: 20,
                    maxReservedStock: 10,
                    isLimitedTime: true,
                    startAt: now.AddMinutes(-60),
                    endAt: now.AddHours(3)
                ));

                // 2. Active - Fixed Amount (Seasonal Sale)
                var variant2 = variants.ElementAtOrDefault(1);
                if (variant2 != null)
                {
                    promotions.Add(new Promotion().Create(
                        "Active - Fixed Amount (Seasonal Sale)",
                        PromotionTypeEnum.FixedAmount,
                        salePrice: Math.Round(variant2.Price * 0.85m, 2),
                        maxReservedStock: 5,
                        isLimitedTime: true,
                        startAt: now.AddMinutes(-30),
                        endAt: now.AddHours(5)
                    ));
                }

                // 3. Upcoming - Percentage (Pre-order)
                promotions.Add(new Promotion().Create(
                    "Upcoming - Percentage (Pre-order)",
                    PromotionTypeEnum.Percentage,
                    percentage: 15,
                    maxReservedStock: 20,
                    isLimitedTime: true,
                    startAt: now.AddHours(2),
                    endAt: now.AddHours(24)
                ));

                // 4. Upcoming - Fixed Amount (Early Bird)
                var variant4 = variants.ElementAtOrDefault(3);
                if (variant4 != null)
                {
                    promotions.Add(new Promotion().Create(
                        "Upcoming - Fixed Amount (Early Bird)",
                        PromotionTypeEnum.FixedAmount,
                        salePrice: Math.Round(variant4.Price * 0.9m, 2),
                        maxReservedStock: 15,
                        isLimitedTime: true,
                        startAt: now.AddHours(4),
                        endAt: now.AddHours(12)
                    ));
                }

                // 5. Expired - Percentage (Past Promotion)
                promotions.Add(new Promotion().Create(
                    "Expired - Percentage (Past Promotion)",
                    PromotionTypeEnum.Percentage,
                    percentage: 30,
                    maxReservedStock: 10,
                    isLimitedTime: true,
                    startAt: now.AddDays(-3),
                    endAt: now.AddDays(-1)
                ));

                // 6. Expired - Fixed Amount (Past Promotion)
                var variant6 = variants.ElementAtOrDefault(5);
                if (variant6 != null)
                {
                    promotions.Add(new Promotion().Create(
                        "Expired - Fixed Amount (Past Promotion)",
                        PromotionTypeEnum.FixedAmount,
                        salePrice: Math.Round(variant6.Price * 0.75m, 2),
                        maxReservedStock: 8,
                        isLimitedTime: true,
                        startAt: now.AddDays(-5),
                        endAt: now.AddDays(-2)
                    ));
                }

                // 7. Active - No time limit (Always on sale)
                var variant7 = variants.ElementAtOrDefault(6);
                if (variant7 != null)
                {
                    promotions.Add(new Promotion().Create(
                        "Active - No time limit (Always on sale)",
                        PromotionTypeEnum.FixedAmount,
                        salePrice: Math.Round(variant7.Price * 0.88m, 2),
                        maxReservedStock: 30,
                        isLimitedTime: false,
                        startAt: null,
                        endAt: null
                    ));
                }

                // 8. Disabled promotion
                var promoDisabled = new Promotion().Create(
                    "Disabled promotion",
                    PromotionTypeEnum.Percentage,
                    percentage: 25,
                    maxReservedStock: 10,
                    isLimitedTime: true,
                    startAt: now.AddMinutes(-10),
                    endAt: now.AddHours(2)
                );
                promoDisabled.IsDisabled = true;
                promotions.Add(promoDisabled);

                // 9. Active - Percentage, no time limit (Clearance Sale)
                promotions.Add(new Promotion().Create(
                    "Active - Percentage (Clearance Sale)",
                    PromotionTypeEnum.Percentage,
                    percentage: 10,
                    maxReservedStock: 50,
                    isLimitedTime: false,
                    startAt: null,
                    endAt: null
                ));

                // 10. Upcoming - Fixed Amount (Holiday Prep)
                var variant16 = variants.ElementAtOrDefault(16);
                if (variant16 != null)
                {
                    promotions.Add(new Promotion().Create(
                        "Upcoming - Fixed Amount (Holiday Prep)",
                        PromotionTypeEnum.FixedAmount,
                        salePrice: Math.Round(variant16.Price * 0.92m, 2),
                        maxReservedStock: 20,
                        isLimitedTime: true,
                        startAt: now.AddDays(1),
                        endAt: now.AddDays(10)
                    ));
                }

                context.Promotions.AddRange(promotions);
                context.SaveChanges();
            }

            // ==================== Staffs (10) ====================
            if (!context.Staffs.Any())
            {
                var staffPassword = BCrypt.Net.BCrypt.HashPassword("Staff@123");
                var now = DateTime.UtcNow;

                var staffs = new[]
                {
                    new Staff { FullName = "Nguyễn Văn An",    Email = "an.nguyen@electronexus.com",    PasswordHash = staffPassword, Role = RoleEnum.Staff, IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Staff { FullName = "Trần Thị Bình",    Email = "binh.tran@electronexus.com",    PasswordHash = staffPassword, Role = RoleEnum.Staff, IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Staff { FullName = "Lê Hoàng Cường",   Email = "cuong.le@electronexus.com",     PasswordHash = staffPassword, Role = RoleEnum.Staff, IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Staff { FullName = "Phạm Thị Dung",    Email = "dung.pham@electronexus.com",    PasswordHash = staffPassword, Role = RoleEnum.Staff, IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Staff { FullName = "Hoàng Văn Em",     Email = "em.hoang@electronexus.com",     PasswordHash = staffPassword, Role = RoleEnum.Staff, IsActive = false, IsDeleted = false, CreatedAt = now },
                    new Staff { FullName = "Vũ Thị Giang",     Email = "giang.vu@electronexus.com",     PasswordHash = staffPassword, Role = RoleEnum.Staff, IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Staff { FullName = "Đặng Văn Hùng",    Email = "hung.dang@electronexus.com",    PasswordHash = staffPassword, Role = RoleEnum.Staff, IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Staff { FullName = "Bùi Thị Kim",      Email = "kim.bui@electronexus.com",      PasswordHash = staffPassword, Role = RoleEnum.Admin, IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Staff { FullName = "Ngô Văn Long",     Email = "long.ngo@electronexus.com",     PasswordHash = staffPassword, Role = RoleEnum.Staff, IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Staff { FullName = "Đỗ Thị Mai",       Email = "mai.do@electronexus.com",       PasswordHash = staffPassword, Role = RoleEnum.Staff, IsActive = true,  IsDeleted = false, CreatedAt = now },
                };

                context.Staffs.AddRange(staffs);
                context.SaveChanges();
            }

            // ==================== Customers (10) ====================
            if (!context.Customers.Any())
            {
                var customerPassword = BCrypt.Net.BCrypt.HashPassword("Customer@123");
                var now = DateTime.UtcNow;

                var customers = new[]
                {
                    new Customer { FullName = "Phan Minh Anh",     Email = "anh.phan@gmail.com",     PhoneNumber = "0901000001", PasswordHash = customerPassword, Role = RoleEnum.Customer, Points = 120,  IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Customer { FullName = "Trịnh Thu Ba",      Email = "ba.trinh@gmail.com",     PhoneNumber = "0901000002", PasswordHash = customerPassword, Role = RoleEnum.Customer, Points = 45,   IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Customer { FullName = "Lý Gia Bảo",        Email = "bao.ly@gmail.com",       PhoneNumber = "0901000003", PasswordHash = customerPassword, Role = RoleEnum.Customer, Points = 0,    IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Customer { FullName = "Đinh Thị Cẩm",      Email = "cam.dinh@gmail.com",     PhoneNumber = "0901000004", PasswordHash = customerPassword, Role = RoleEnum.Customer, Points = 300,  IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Customer { FullName = "Huỳnh Văn Đạt",     Email = "dat.huynh@gmail.com",    PhoneNumber = "0901000005", PasswordHash = customerPassword, Role = RoleEnum.Customer, Points = 85,   IsActive = false, IsDeleted = false, CreatedAt = now },
                    new Customer { FullName = "Mai Thị Hoa",       Email = "hoa.mai@gmail.com",      PhoneNumber = "0901000006", PasswordHash = customerPassword, Role = RoleEnum.Customer, Points = 210,  IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Customer { FullName = "Vương Đức Huy",     Email = "huy.vuong@gmail.com",    PhoneNumber = "0901000007", PasswordHash = customerPassword, Role = RoleEnum.Customer, Points = 15,   IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Customer { FullName = "Tô Ngọc Lan",       Email = "lan.to@gmail.com",       PhoneNumber = "0901000008", PasswordHash = customerPassword, Role = RoleEnum.Customer, Points = 500,  IsActive = true,  IsDeleted = false, CreatedAt = now },
                    new Customer { FullName = "Châu Bảo Long",     Email = "long.chau@gmail.com",    PhoneNumber = "0901000009", PasswordHash = customerPassword, Role = RoleEnum.Customer, Points = 60,   IsActive = false, IsDeleted = false, CreatedAt = now },
                    new Customer { FullName = "Kiều Thị Ngọc",     Email = "ngoc.kieu@gmail.com",    PhoneNumber = "0901000010", PasswordHash = customerPassword, Role = RoleEnum.Customer, Points = 175,  IsActive = true,  IsDeleted = false, CreatedAt = now },
                };

                context.Customers.AddRange(customers);
                context.SaveChanges();
            }

            // ==================== Orders + OrderItems (10 orders, 15 items) ====================
            if (!context.Orders.Any())
            {
                var customers = context.Customers.OrderBy(c => c.CustomerId).ToList();
                var variants = context.ProductVariants.OrderBy(v => v.CreatedAt).ToList();
                var statuses = new[] { "Pending", "Processing", "Completed", "Cancelled" };

                var orders = new List<Order>();
                for (int i = 0; i < 10; i++)
                {
                    var customer = customers[i % customers.Count];
                    var status = statuses[i % statuses.Length];
                    orders.Add(Order.Create(customer.CustomerId, null, 0m, status));
                }
                context.Orders.AddRange(orders);
                context.SaveChanges();

                var orderItems = new List<OrderItem>
                {
                    OrderItem.Create(orders[0].OrderId, variants[0].ProductVariantId, 1, variants[0].Price),
                    OrderItem.Create(orders[0].OrderId, variants[7].ProductVariantId, 2, variants[7].Price),

                    OrderItem.Create(orders[1].OrderId, variants[3].ProductVariantId, 1, variants[3].Price),

                    OrderItem.Create(orders[2].OrderId, variants[1].ProductVariantId, 1, variants[1].Price),
                    OrderItem.Create(orders[2].OrderId, variants[9].ProductVariantId, 3, variants[9].Price),

                    OrderItem.Create(orders[3].OrderId, variants[5].ProductVariantId, 1, variants[5].Price),

                    OrderItem.Create(orders[4].OrderId, variants[10].ProductVariantId, 1, variants[10].Price),
                    OrderItem.Create(orders[4].OrderId, variants[16].ProductVariantId, 2, variants[16].Price),

                    OrderItem.Create(orders[5].OrderId, variants[2].ProductVariantId, 1, variants[2].Price),

                    OrderItem.Create(orders[6].OrderId, variants[11].ProductVariantId, 1, variants[11].Price),
                    OrderItem.Create(orders[6].OrderId, variants[8].ProductVariantId, 1, variants[8].Price),

                    OrderItem.Create(orders[7].OrderId, variants[13].ProductVariantId, 1, variants[13].Price),

                    OrderItem.Create(orders[8].OrderId, variants[4].ProductVariantId, 2, variants[4].Price),
                    OrderItem.Create(orders[8].OrderId, variants[9].ProductVariantId, 1, variants[9].Price),

                    OrderItem.Create(orders[9].OrderId, variants[17].ProductVariantId, 1, variants[17].Price),
                };

                context.OrderItems.AddRange(orderItems);
                context.SaveChanges();

                // Recalculate totals based on order items just created
                foreach (var order in orders)
                {
                    var total = orderItems
                        .Where(oi => oi.OrderId == order.OrderId)
                        .Sum(oi => oi.Quantity * oi.PriceAtPurchase);
                    order.Update(null, total, order.Status);
                }
                context.SaveChanges();
            }

            // ==================== ProductReviews (10) ====================
            if (!context.ProductReviews.Any())
            {
                var customers = context.Customers.OrderBy(c => c.CustomerId).ToList();
                var products = context.Products.OrderBy(p => p.ProductId).ToList();

                var reviews = new[]
                {
                    ProductReview.Create(customers[0].CustomerId, products[0].ProductId, 5, "Máy chạy mượt, pin trâu, rất hài lòng!"),
                    ProductReview.Create(customers[1].CustomerId, products[4].ProductId, 4, "Camera đẹp nhưng hơi nóng máy khi chơi game."),
                    ProductReview.Create(customers[2].CustomerId, products[7].ProductId, 5, "Tai nghe âm thanh tốt, chống ồn khá ổn."),
                    ProductReview.Create(customers[3].CustomerId, products[1].ProductId, 3, "Cấu hình mạnh nhưng giá hơi cao."),
                    ProductReview.Create(customers[4].CustomerId, products[10].ProductId, 4, "Máy tính bảng dùng học tập rất tiện."),
                    ProductReview.Create(customers[5].CustomerId, products[5].ProductId, 5, "Điện thoại đáng tiền, giao hàng nhanh."),
                    ProductReview.Create(customers[6].CustomerId, products[8].ProductId, 2, "Sạc dự phòng sạc chậm hơn mong đợi."),
                    ProductReview.Create(customers[7].CustomerId, products[2].ProductId, 5, "Laptop mỏng nhẹ, màn hình đẹp, rất đáng mua."),
                    ProductReview.Create(customers[8].CustomerId, products[6].ProductId, 4, "Điện thoại nhỏ gọn, phù hợp nữ dùng."),
                    ProductReview.Create(customers[9].CustomerId, products[11].ProductId, 3, "Tablet ổn trong tầm giá, RAM hơi thấp."),
                };

                context.ProductReviews.AddRange(reviews);
                context.SaveChanges();
            }

            // ==================== CartItems (10) ====================
            if (!context.CartItems.Any())
            {
                var customers = context.Customers.OrderBy(c => c.CustomerId).ToList();
                var variants = context.ProductVariants.OrderBy(v => v.CreatedAt).ToList();

                var cartItems = new[]
                {
                    CartItem.Create(customers[0].CustomerId, variants[2].ProductVariantId, 1),
                    CartItem.Create(customers[0].CustomerId, variants[9].ProductVariantId, 2),
                    CartItem.Create(customers[1].CustomerId, variants[5].ProductVariantId, 1),
                    CartItem.Create(customers[2].CustomerId, variants[16].ProductVariantId, 3),
                    CartItem.Create(customers[3].CustomerId, variants[1].ProductVariantId, 1),
                    CartItem.Create(customers[4].CustomerId, variants[7].ProductVariantId, 2),
                    CartItem.Create(customers[5].CustomerId, variants[13].ProductVariantId, 1),
                    CartItem.Create(customers[6].CustomerId, variants[10].ProductVariantId, 1),
                    CartItem.Create(customers[7].CustomerId, variants[15].ProductVariantId, 1),
                    CartItem.Create(customers[8].CustomerId, variants[17].ProductVariantId, 2),
                };

                context.CartItems.AddRange(cartItems);
                context.SaveChanges();
            }
        }
    }
}