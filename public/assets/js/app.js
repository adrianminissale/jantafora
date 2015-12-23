$(document).ready(function(){
  $(".menu-button").click(function(){
    $("header nav").fadeToggle("slow");
  });
  $(".filters span").click(function(){
    $(".filters-dropdown").toggleClass("active");
    $(".filters span").toggleClass("active");
  });
});
