$(document).ready(function() {
  // On click (player hit button) display player next card ajaxified
  $(document).on('click', '#player_hit_form input', function() {
    $.ajax({
      type: 'POST',
      url: '/player/hit',
    }).done(function(msg) {
      $('body').replaceWith(function() {
        return $(msg).find('body');
      });
    });


    return false;
  })

  // On click (stand button) display dealer next card ajaxified
  $(document).on('click', '#player_stand_form input', function() {
    $.ajax({
      type: 'POST',
      url: '/player/stand',
    }).done(function(msg) {
      $('#game').replaceWith(function() {
        return $(msg).find('#game');
      });
    });

    return false;
  });

  // On click (dealer next card button) display next dealer card ajaxified
  $(document).on('click', '#dealer_hit_form input', function() {
    $.ajax({
      type: 'POST',
      url: '/dealer/hit',
    }).done(function(msg) {
      $('#game').replaceWith(function() {
        return $(msg).find('#game');
      });
    });

    return false;
  });

});