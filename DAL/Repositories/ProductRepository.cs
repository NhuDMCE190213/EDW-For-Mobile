using DAL.Data;
using DAL.Models;
using DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DAL.Repositories
{
    public class ProductRepository : IProductRepository
    {
        private readonly AppDbContext _context;
        public ProductRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<List<Product>> GetAllProductsAsync()
        {
            var products = await _context.Products.AsNoTracking().Include(p => p.Category).ToListAsync();
            return products;
        }

        public async Task<Product?> GetProductByIdAsync(int productId)
        {
            return await _context.Products
                .AsNoTracking()
                .Include(p => p.Category)
                .Include(p => p.ProductVariants)
                .ThenInclude(pv => pv.Promotion)
                .FirstOrDefaultAsync(p => p.ProductId == productId);
        }

        public async Task<Product> CreateProductAsync(Product product)
        {
            _context.Products.Add(product);
            await _context.SaveChangesAsync();
            return product;
        }

        public async Task<bool> UpdateProductAsync(Product product)
        {
            var existingProduct = await _context.Products.FindAsync(product.ProductId);
            if (existingProduct != null)
            {
                existingProduct.Update(
                    product.ProductName, 
                    product.Brand, 
                    product.CategoryId,
                    product.ImageUrl
                );
                await _context.SaveChangesAsync();
                return true;
            }
            return false;
        }

        public async Task<bool> DeleteProductAsync(int productId)
        {
            var product = await _context.Products.FirstOrDefaultAsync(p => p.ProductId == productId);
            if (product != null)
            {
                product.Delete();
                await _context.SaveChangesAsync();
                return true;
            }
            return false;
        }

        public async Task<List<Product>> GetProductsByCategoryIdAsync(int categoryId)
        {
            var products = await _context.Products
                .AsNoTracking()
                .Include(p => p.Category)
                .Where(p => p.CategoryId == categoryId)
                .ToListAsync();
            return products;
        }

        public async Task<Product?> GetProductWithVariantsAsync(Guid productVariantId)
        {
            var product = await _context.Products
                .AsNoTracking()
                .Include(p => p.Category)
                .Include(p => p.ProductVariants)
                .FirstOrDefaultAsync(p => p.ProductVariants.Any(pv => pv.ProductVariantId == productVariantId));
            return product;
        }

        public async Task<List<Product>> SearchByNameAsync(string keyword)
        {
            return await _context.Products
                .AsNoTracking()
                .Include(p => p.Category)
                .Where(p => p.ProductName.Contains(keyword))
                .ToListAsync();
        }
    }
}
