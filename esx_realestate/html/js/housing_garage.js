const HousingGarage = {
    Open: function() {
        $('.housing-garage .garage-list').empty();
        $('.housing-garage .garage-count').text('0');
        $('.housing-garage .garage-status').text('Looking for vehicles...').removeClass('error');
        $('.housing-garage').fadeIn(120);
        currentMenu = 'housing_garage';
    },
    Close: function() {
        $('.housing-garage').fadeOut(120);
        if (currentMenu === 'housing_garage') currentMenu = null;
    },
    Update: function(message) {
        const vehicles = Array.isArray(message.data) ? message.data : [];
        const list = $('.housing-garage .garage-list').empty();
        $('.housing-garage .garage-count').text(vehicles.length);
        vehicles.forEach(vehicle => {
            const row = $('<div class="wardrobe-row"></div>');
            const details = $('<div class="wardrobe-row-details"></div>');
            $('<div class="wardrobe-row-name"></div>').text(vehicle.name || 'Vehicle').appendTo(details);
            $('<div></div>').text(vehicle.plate || '').css({fontSize: '.8em', color: '#aaa'}).appendTo(details);
            row.append($('<span class="wardrobe-slot"><i class="fa-solid fa-car"></i></span>'), details);
            list.append(row);
        });
        $('.housing-garage .garage-status').text(vehicles.length ? 'Parking is not available yet.' : 'No owned vehicles nearby. Parking is not available yet.');
    },
    Error: function(message) { $('.housing-garage .garage-status').text(message.data || 'Garage unavailable.').addClass('error'); },
    requestClose: function() { $.post(`https://${GetParentResourceName()}/housingGarage:close`, JSON.stringify({})); }
};
$('.housing-garage .garage-close').on('click', function() { HousingGarage.requestClose(); });
