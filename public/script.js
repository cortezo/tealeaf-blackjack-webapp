$(document).ready(function() {
  player_hits();
  player_stays();
  dealer_hits();
});

  // On click (player hit button) display player next card ajaxified
function player_hits() {
  $(document).on('click', 'form#player_hit_form input', function() {
    $.ajax({
      type: 'POST',
      url: '/player/hit',
    }).done(function(msg) {
      $('#player_area').replaceWith(function() {
        return $(msg).find('#player_area');
      });
    });

    return false;
  })
}

  // On click (stand button) display dealer next card ajaxified
function player_stays() {
  $(document).on('click', 'form#player_stand_form input', function() {
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
}

function dealer_hits() {
  // On click (dealer next card button) display next dealer card ajaxified
  $(document).on('click', 'form#dealer_hit_form input', function() {
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
}