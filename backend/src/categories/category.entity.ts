import {
  Column,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  type Relation,
} from 'typeorm';
import { Book } from '../books/book.entity.js';

@Entity({ name: 'category' })
export class Category {
  @PrimaryGeneratedColumn({
    name: 'category_id',
    type: 'bigint',
    unsigned: true,
  })
  categoryId!: number;

  @Column({ type: 'varchar', length: 50, unique: true })
  name!: string;

  @OneToMany(() => Book, (book) => book.category)
  books!: Relation<Book[]>;
}
