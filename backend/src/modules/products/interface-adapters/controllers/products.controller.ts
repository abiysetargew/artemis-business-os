import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ProductsUseCase } from '../../application/use-cases/products.use-case';
import {
  CreateProductCategoryDto,
  UpdateProductCategoryDto,
  CreateProductDto,
  UpdateProductDto,
  ProductResponseDto,
  ProductCategoryResponseDto,
} from '../../application/dto/product.dto';
import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../../common/guards/roles.guard';
import { Roles } from '../../../../common/decorators/roles.decorator';

@Controller('products')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ProductsController {
  constructor(private readonly productsUseCase: ProductsUseCase) {}

  // --- Categories ---
  @Get('categories')
  async findAllCategories(): Promise<ProductCategoryResponseDto[]> {
    return this.productsUseCase.findAllCategories();
  }

  @Post('categories')
  @Roles('ADMIN')
  @HttpCode(HttpStatus.CREATED)
  async createCategory(
    @Body() dto: CreateProductCategoryDto,
  ): Promise<ProductCategoryResponseDto> {
    return this.productsUseCase.createCategory(dto);
  }

  @Patch('categories/:id')
  @Roles('ADMIN')
  async updateCategory(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateProductCategoryDto,
  ): Promise<ProductCategoryResponseDto> {
    return this.productsUseCase.updateCategory(id, dto);
  }

  @Delete('categories/:id')
  @Roles('ADMIN')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteCategory(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.productsUseCase.deleteCategory(id);
  }

  // --- Products ---
  @Get()
  async findAllProducts(
    @Query('categoryId') categoryId?: string,
    @Query('type') type?: string,
    @Query('search') search?: string,
  ): Promise<ProductResponseDto[]> {
    return this.productsUseCase.findAllProducts({ categoryId, type, search });
  }

  @Get(':id')
  async findProductById(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ProductResponseDto> {
    return this.productsUseCase.findProductById(id);
  }

  @Post()
  @Roles('ADMIN')
  @HttpCode(HttpStatus.CREATED)
  async createProduct(
    @Body() dto: CreateProductDto,
  ): Promise<ProductResponseDto> {
    return this.productsUseCase.createProduct(dto);
  }

  @Patch(':id')
  @Roles('ADMIN')
  async updateProduct(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateProductDto,
  ): Promise<ProductResponseDto> {
    return this.productsUseCase.updateProduct(id, dto);
  }

  @Delete(':id')
  @Roles('ADMIN')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteProduct(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.productsUseCase.deleteProduct(id);
  }
}
