/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package business.entities;

public class Book {
private int number; //1-a iteracja
private BookTitle bookTitle; //1-a iteracja
public Book() { }
public int getNumber() { //2-a iteracja
return number;
}
public void setNumber(int number) { //2-a iteracja
this.number = number;
}
public BookTitle getBookTitle() { //2-a iteracja
return bookTitle;
}
public void setBookTitle(BookTitle booktitle) { //2-a iteracja
this.bookTitle = booktitle;
}
@Override
public int hashCode() { //2-a iteracja
int hash = 0;
hash += (number != 0 ? number : 0);
return hash;
}
@Override
public boolean equals(Object obj) { //2-a iteracja
return number == ((Book) obj).getNumber();
}
@Override
public String toString() // your code here
{
String bookdata = bookTitle.toString();
bookdata += " Number: " + getNumber();
return bookdata;
}
/* public boolean passedPeriod(Object data) { //kolejne iteracje
return true; }
public void startedPeriod(Object data){ //kolejne iteracje
}
public Date getPeriod() { //kolejne iteracje
throw new UnsupportedOperationException("Not supported yet."); }
public void setPeriod(Date period) { } */
}

