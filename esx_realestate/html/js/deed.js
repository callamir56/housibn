const Deed = {
    isOpen: false,
    busy: false,
    generation: 0,
    request: function(action) {
        if (this.busy) return;
        this.busy = true;
        const current = this.generation;
        $('.property-deed .deed-sign').prop('disabled', true);
        $('.property-deed .deed-status').text('Loading...');
        $.post(`https://${GetParentResourceName()}/deed:request`, JSON.stringify({action}))
            .done(data => {
                if (!this.isOpen || current !== this.generation) return;
                this.busy = false;
                if (!data || !data.ok) { $('.property-deed .deed-status').text(data?.reason || 'Deed unavailable.'); $('.property-deed .deed-sign').prop('disabled', false); return; }
                this.render(data);
            })
            .fail(() => { if (this.isOpen && current === this.generation) { this.busy = false; $('.property-deed .deed-status').text('Deed unavailable.'); $('.property-deed .deed-sign').prop('disabled', false); } });
    },
    render: function(data) {
        const box = $('.property-deed');
        box.find('.deed-id').text(`#${data.id}`);
        box.find('.deed-name').text(data.name || '');
        box.find('.deed-address').text(data.address || 'Not available');
        box.find('.deed-owner').text(data.owner || 'Unknown owner');
        box.find('.deed-issued').text(`Viewed ${data.issued || ''}`);
        box.find('.deed-signature').text(data.signature || '');
        box.find('.deed-signed-date').text(data.signedAt ? `· ${data.signedAt}` : '');
        box.find('.deed-sign').toggle(!data.signature).prop('disabled', false);
        box.find('.deed-status').text('');
    },
    open: function() {
        if (this.isOpen) return;
        this.isOpen = true; this.busy = false; this.generation++;
        $('.property-deed .deed-signature, .property-deed .deed-owner, .property-deed .deed-name, .property-deed .deed-address, .property-deed .deed-id, .property-deed .deed-signed-date, .property-deed .deed-issued').text('');
        $('.housing_manage').hide(); $('.property-deed').fadeIn(150);
        this.request('view');
    },
    hide: function() { this.isOpen = false; this.busy = false; this.generation++; $('.property-deed').hide(); },
    close: function() { if (!this.isOpen) return; this.hide(); if (currentMenu === 'housing_manage') $('.housing_manage').fadeIn(120); }
};
$('.property-deed .deed-sign').on('click', function() { Deed.request('sign'); });
$('.property-deed .deed-back').on('click', function() { Deed.close(); });
