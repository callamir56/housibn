const HousingGarage = {
    post: function(action, data) {
        $.post(`https://${GetParentResourceName()}/housingGarage:${action}`, JSON.stringify(data || {}))
            .done(result => { if (result && result.ok === false) this.Error({data: 'Try again.'}); })
            .fail(() => this.Error({data: 'Garage unavailable.'}));
    },
    Open: function() {
        $('.housing-garage .garage-list').empty();
        $('.housing-garage .garage-count').text('');
        $('.housing-garage .garage-status').text('Loading...').removeClass('error');
        $('.housing-garage').fadeIn(120); currentMenu = 'housing_garage';
    },
    Close: function() { $('.housing-garage').fadeOut(120); if (currentMenu === 'housing_garage') currentMenu = null; },
    Update: function(message) {
        const data = message.data || {}, vehicles = data.vehicles || [], list = $('.housing-garage .garage-list').empty();
        const parked = data.parked;
        $('.housing-garage .garage-count').text(parked ? '1 / 1' : '0 / 1');
        $('.housing-garage h2').text(parked ? 'Parked' : 'Nearby vehicles');
        if (parked) {
            const row=$('<div class="wardrobe-row"></div>'), details=$('<div class="wardrobe-row-details"></div>');
            $('<div class="wardrobe-row-name"></div>').text(parked.plate).appendTo(details);
            row.append($('<span class="wardrobe-slot"><i class="fa-solid fa-car"></i></span>'),details);
            if (parked.canTake) $('<button type="button" class="wardrobe-wear">Take out</button>').css({border:0,borderRadius:'.35em',padding:'.45em .8em'}).on('click',function(){ $('.housing-garage button').prop('disabled',true); HousingGarage.post('take'); }).appendTo(row);
            list.append(row);
        } else vehicles.forEach(vehicle => {
            const row=$('<div class="wardrobe-row"></div>'), details=$('<div class="wardrobe-row-details"></div>');
            $('<div class="wardrobe-row-name"></div>').text(vehicle.name || 'Vehicle').appendTo(details);
            $('<div></div>').text(vehicle.plate || '').css({fontSize:'.8em',color:'#aaa'}).appendTo(details);
            row.append($('<span class="wardrobe-slot"><i class="fa-solid fa-car"></i></span>'),details);
            $('<button type="button" class="wardrobe-wear">Park</button>').css({border:0,borderRadius:'.35em',padding:'.45em .8em'}).on('click',function(){ $('.housing-garage button').prop('disabled',true); HousingGarage.post('park',{id:vehicle.id}); }).appendTo(row);
            list.append(row);
        });
        $('.housing-garage button').prop('disabled',false);
        $('.housing-garage .garage-status').text(!parked && !vehicles.length ? 'No vehicles nearby.' : '').removeClass('error');
    },
    Error: function(message) { $('.housing-garage button').prop('disabled',false); $('.housing-garage .garage-status').text(message.data || 'Garage unavailable.').addClass('error'); },
    requestClose: function() { this.post('close'); }
};
$('.housing-garage .garage-close').on('click', function() { HousingGarage.requestClose(); });
