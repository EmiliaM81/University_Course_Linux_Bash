/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package business;

import business.entities.Book;
import business.entities.BookTitle;
public class Factory {
// static final long day = 24 * 60 * 60 * 1000; //kolejne iteracje
public BookTitle createBookTitle(String data[]) { //1-a iteracja
BookTitle booktitle = null;
switch (Integer.parseInt(data[0])) //what_title_book_type
{
case 0:
booktitle = new BookTitle(); //BookTitle object for searching
booktitle.setISBN(data[1]);
break;
case 1:
booktitle = new BookTitle(); //BookTitle object for persisting
booktitle.setAuthor(data[1]);
booktitle.setTitle(data[2]);
booktitle.setISBN(data[3]);
booktitle.setPublisher(data[4]);
break;
}
return booktitle;
}
public Book createBook(String data[]) { //2-a iteracja
Book book = null;
switch (Integer.parseInt(data[0])) //what_book_type
{
case 0:
book = new Book(); //TBook object for persisting
book.setNumber(Integer.parseInt(data[1]));
break;
}
return book;
}
/* static public Date mdays(String data) { 
    throw new UnsupportedOperationException("Not supported yet.");
}*/
}