const Wardrobe = {
    outfits: [],
    pendingDelete: null,
    busy: false,

    post: function(action, data) {
        $.post(`https://${GetParentResourceName()}/wardrobe:${action}`, JSON.stringify(data || {}))
            .done(result => { if (result && result.ok === false) this.Error({data: 'Unable to complete the request.'}); })
            .fail(() => this.Error({data: 'Unable to reach the wardrobe.'}));
    },
    Open: function() {
        this.outfits = [];
        this.pendingDelete = null;
        this.busy = false;
        $('.wardrobe:not(.housing-garage) .wardrobe-status').text('Loading...').removeClass('error success');
        $('#wardrobe-name').val('');
        this.render();
        $('.wardrobe:not(.housing-garage)').fadeIn(120);
        currentMenu = 'wardrobe';
    },
    Close: function() {
        $('.wardrobe:not(.housing-garage)').fadeOut(120);
        this.busy = false;
        if (currentMenu === 'wardrobe') currentMenu = null;
    },
    Update: function(message) {
        this.outfits = Array.isArray(message.data) ? message.data : [];
        this.pendingDelete = null;
        this.busy = false;
        this.render();
        if ($('.wardrobe:not(.housing-garage) .wardrobe-status').text() === 'Loading...') $('.wardrobe:not(.housing-garage) .wardrobe-status').text('');
    },
    Error: function(message) {
        this.busy = false;
        this.render();
        $('.wardrobe:not(.housing-garage) .wardrobe-status').text(message.data || 'Something went wrong.').removeClass('success').addClass('error');
    },
    Success: function(message) {
        this.busy = false;
        this.render();
        $('.wardrobe:not(.housing-garage) .wardrobe-status').text(message.data || 'Done.').removeClass('error').addClass('success');
    },
    requestClose: function() { this.post('close'); },
    render: function() {
        const self = this;
        const list = $('.wardrobe:not(.housing-garage) .wardrobe-list').empty();
        const bySlot = new Map(this.outfits.map(outfit => [Number(outfit.slot), outfit]));
        $('.wardrobe:not(.housing-garage) .wardrobe-count').text(`${this.outfits.length} / 5`);
        for (let slot = 1; slot <= 5; slot++) {
            const outfit = bySlot.get(slot);
            const row = $('<div class="wardrobe-row"></div>');
            const number = $('<span class="wardrobe-slot"></span>').text(String(slot).padStart(2, '0'));
            const details = $('<div class="wardrobe-row-details"></div>');
            $('<div class="wardrobe-row-name"></div>').text(outfit ? outfit.name : 'Empty slot').appendTo(details);
            row.append(number, details);
            if (outfit) {
                const actions = $('<div class="wardrobe-row-actions"></div>');
                if (this.pendingDelete === slot) {
                    $('<button type="button" class="wardrobe-confirm">Delete</button>').prop('disabled', this.busy).on('click', function() {
                        if (self.busy) return;
                        self.busy = true; self.render(); self.post('delete', {slot});
                    }).appendTo(actions);
                    $('<button type="button" class="wardrobe-cancel">Cancel</button>').prop('disabled', this.busy).on('click', function() {
                        self.pendingDelete = null; self.render();
                    }).appendTo(actions);
                } else {
                    $('<button type="button" class="wardrobe-wear"><i class="fa-solid fa-check"></i> Wear</button>').prop('disabled', this.busy).on('click', function() {
                        if (self.busy) return;
                        self.busy = true; self.render(); self.post('wear', {slot});
                    }).appendTo(actions);
                    $('<button type="button" class="wardrobe-delete" aria-label="Delete outfit"><i class="fa-solid fa-trash-can"></i></button>').prop('disabled', this.busy).on('click', function() {
                        self.pendingDelete = slot; self.render();
                    }).appendTo(actions);
                }
                row.append(actions);
            } else row.addClass('empty');
            list.append(row);
        }
        const full = this.outfits.length >= 5;
        $('.wardrobe-save input, .wardrobe-save button').prop('disabled', this.busy || full);
        $('#wardrobe-name').attr('placeholder', full ? 'Wardrobe full' : 'Outfit name');
    }
};

$('.wardrobe:not(.housing-garage) .wardrobe-close').on('click', function() { Wardrobe.requestClose(); });
$('.wardrobe-save').on('submit', function(event) {
    event.preventDefault();
    const name = String($('#wardrobe-name').val() || '').trim();
    if (Wardrobe.busy || Wardrobe.outfits.length >= 5) return;
    if (!name || [...name].length > 40) return Wardrobe.Error({data: 'Enter a name (1–40 characters).'});
    Wardrobe.busy = true;
    Wardrobe.render();
    $('.wardrobe:not(.housing-garage) .wardrobe-status').text('Saving...').removeClass('error success');
    Wardrobe.post('save', {name});
});
