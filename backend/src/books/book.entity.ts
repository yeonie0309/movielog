import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  type Relation,
} from 'typeorm';
import { Category } from '../categories/category.entity.js';

@Entity({ name: 'book' })
@Index('uk_book_title', ['title'], { unique: true })
export class Book {
  @PrimaryGeneratedColumn({ name: 'book_id', type: 'bigint', unsigned: true })
  bookId!: number;

  @ManyToOne(() => Category, (category) => category.books, {
    nullable: false,
    onDelete: 'RESTRICT',
    onUpdate: 'RESTRICT',
  })
  @JoinColumn({ name: 'category_id' })
  category!: Relation<Category>;

  @Column({ type: 'varchar', length: 100 })
  title!: string;

  @Column({ type: 'text', nullable: true })
  description!: string | null;

  @Column({ name: 'is_available', type: 'boolean', default: true })
  isAvailable!: boolean;
}
