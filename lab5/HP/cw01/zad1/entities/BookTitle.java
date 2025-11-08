/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package business.entities;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Objects;
import business.Factory;

public class BookTitle {
private String publisher; //1-a iteracja
private String ISBN; //1-a iteracja
private String title; //1-a iteracja
private String author; //1-a iteracja
List<Book> books; //1-a iteracja
public BookTitle() {
books = new ArrayList(); //1-a iteracja
}
public String getPublisher() { //1-a iteracja
return publisher;
}
public void setPublisher(String publisher) { //1-a iteracja
this.publisher = publisher;
}
public String getISBN() { //1-a iteracja
return ISBN;
}
public void setISBN(String ISBN) { //1-a iteracja
this.ISBN = ISBN;
}
public String getTitle() { //1-a iteracja
return title;
}
public void setTitle(String title) { //1-a iteracja
this.title = title;
}
public String getAuthor() { //1-a iteracja
return author;
}
public void setAuthor(String author) { //1-a iteracja
this.author = author;
}
public List<Book> getBooks() { //1-a iteracja
return books;
}
public void setBooks(List<Book> books) { //1-a iteracja
this.books = books;
}
@Override
public int hashCode() { //1-a iteracja
int hash = 5;
hash = 53 * hash + Objects.hashCode(this.ISBN);
return hash;
}
@Override
public boolean equals(Object obj) { //1-a iteracja
boolean result = false;
if (getISBN().equals(((BookTitle) obj).getISBN()))
result = true;
return result;
}
@Override
public String toString() {
String booktitledata = "\nTitle: " + getTitle();
booktitledata += " Author: " + getAuthor();
booktitledata += " ISBN: " + getISBN();
booktitledata += " Publisher: " + getPublisher();
return booktitledata;
}
public ArrayList<String> addBook(String data[]) { //2-a iteracja
Factory factory = new Factory();
Book newbook;
newbook = factory.createBook(data);
if (findBook(newbook) == null) {
books.add(newbook);
newbook.setBookTitle(this);
return getDataOfBooks(); }
return null;
}
public Book findBook(Book book) { //2-a iteracja
int idx;
if ((idx = books.indexOf(book)) != -1) {
book = books.get(idx);
return book; }
return null;
}
public ArrayList<String> getDataOfBooks() { //2-a iteracja
ArrayList<String> dataofbooks = new ArrayList<>();
Iterator<Book> bookiterator = books.iterator();
while (bookiterator.hasNext()) {
Book nextbook = bookiterator.next();
dataofbooks.add(nextbook.toString());}
return dataofbooks;
}
/* public String[]dataOfBookTitle () {
throw new UnsupportedOperationException("Not supported yet."); } //kolejne iteracje
public String searchAccessibleBook (Object data) {
throw new UnsupportedOperationException("Not supported yet."); }
public String getActor() {
throw new UnsupportedOperationException("Not supported yet."); }
public void setActor(String val) { }
*/
}